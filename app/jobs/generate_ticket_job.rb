# app/jobs/generate_ticket_job.rb
class GenerateTicketJob < ApplicationJob
  queue_as :default
  retry_on ActiveRecord::ConnectionTimeoutError, wait: 5.seconds, attempts: 10

  def perform(entry_id)
    entry = Entry.find(entry_id)
  
    ticket_image_path = Rails.root.join('tmp', 'tickets', "ticket_#{entry.code}.png")
  
    FileUtils.mkdir_p(Rails.root.join('tmp', 'tickets')) unless File.directory?(Rails.root.join('tmp', 'tickets'))
  
    return ticket_image_path.to_path if File.exist?(ticket_image_path)
  
    # Generar el QR con menos margen blanco
    qr = RQRCode::QRCode.new(entry.code)
    qr_png = qr.as_png(size: 220, border_modules: 2) # Reduce el margen blanco
  
    qr_path = Rails.root.join('tmp', 'tickets', "qr_#{entry.id}.png")
    File.open(qr_path, 'wb') { |file| file.write(qr_png.to_s) }
  
    # Crear la imagen del código
    code_image_path = Rails.root.join('tmp', 'tickets', "code_#{entry.id}.png")
    MiniMagick::Tool::Convert.new do |convert|
      convert.size '350x50'
      convert.gravity 'center'
      convert.pointsize '30'
      convert.fill 'black'
      convert.background 'white'
      convert << "label:#{entry.code}"
      convert << code_image_path.to_s
    end
  
    # Cargar la imagen base
    base_image_path = case entry.entry_type
    when "general"
      Rails.root.join('app/assets/images/general_template.png')
    when "furama"
      Rails.root.join('app/assets/images/furama_template.png')
    when "premium"
      Rails.root.join('app/assets/images/premium_template.png')
    when "nomad"
      Rails.root.join('app/assets/images/nomad_template.png')
    when "vip"
      Rails.root.join('app/assets/images/sponsor_template.png')
    else
      Rails.root.join('app/assets/images/general_template.png')
    end
    base_image = ChunkyPNG::Image.from_file(base_image_path)
  
    qr_image = ChunkyPNG::Image.from_file(qr_path)
    code_image = ChunkyPNG::Image.from_file(code_image_path)
  
    # Ajustar posiciones
    margin = 35
    qr_x_offset = base_image.width - qr_image.width - margin # Abajo a la derecha
    qr_y_offset = base_image.height - qr_image.height - margin
    base_image.compose!(qr_image, qr_x_offset, qr_y_offset)
  
    # Márgenes separados para el código
    code_left_margin = 700   # Margen izquierdo
    code_bottom_margin = 25 # Margen inferior
    code_x_offset = code_left_margin
    code_y_offset = base_image.height - code_image.height - code_bottom_margin
    base_image.compose!(code_image, code_x_offset, code_y_offset)
  
    # Guardar la imagen final
    base_image.save(ticket_image_path)
  
    # Limpiar archivos temporales
    File.delete(qr_path)
    File.delete(code_image_path)
  
    ticket_image_path.to_path
  end
end
