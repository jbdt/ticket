def can_confirm?(entry)
  %w[sold].include?(entry.status) && current_user.admin?
end

def can_unconfirm?(entry)
  %w[confirmed].include?(entry.status) && current_user.admin?
end

def can_cancel?(entry)
  %w[created sold].include?(entry.status) && current_user.admin?
end

Trestle.resource(:entries) do
  menu do
    item :entries, icon: "fa fa-ticket",
    badge: { text: current_user.admin? ? Entry.count : Entry.where(user: current_user).count },
    priority: 1
  end

  remove_action :destroy, :new

  routes do
    post :cancel, on: :member
    post :confirm, on: :member
    post :unconfirm, on: :member
    get :download_qr_code
    get :download_ticket
  end

  controller do
    def show
      entry = Entry.find(params[:id])

      if current_user.admin? || entry.user_id == current_user.id
        @entry = entry
      else
        flash[:error] = "You are not authorized to view this entry."
        redirect_to entries_admin_index_path
      end
    end

    def cancel
      entry = admin.find_instance(params)
      entry.update(status: 'canceled')
      flash[:message] = {title: "#{entry.code}", message: 'Entry has been canceled successfully.'}
      redirect_to admin.path(:index)
    end

    def confirm
      entry = admin.find_instance(params)
      entry.update(status: 'confirmed')
      flash[:message] = {title: "#{entry.code}", message: 'Entry has been confirmed successfully.'}
      redirect_to admin.path(:index)
    end

    def unconfirm
      entry = admin.find_instance(params)
      entry.update(status: 'sold')
      flash[:message] = {title: "#{entry.code}", message: 'Entry has been unconfirmed successfully.'}
      redirect_to admin.path(:index)
    end

    def download_qr_code
      entry = Entry.find(params[:entries_admin_id])
      qr_code = RQRCode::QRCode.new(entry.code)

      png = qr_code.as_png(size: 300)

      send_data png.to_s,
                type: 'image/png',
                disposition: 'attachment',
                filename: "QR_#{entry.code}.png"
    end

    def download_ticket
      entry = Entry.find(params[:entries_admin_id])
      ticket_path = Rails.root.join('tmp', 'tickets', "ticket_#{entry.code}.png")
    
      if File.exist?(ticket_path)
        send_file ticket_path, filename: "ticket_#{entry.code}.png", type: "image/png", disposition: 'attachment'
      else
        flash[:error] = "Ticket is still being generated. Please try again in 5 minutes."
        redirect_to admin.path(:index)
      end
    end

    private
  
    def entry_params
      params.require(:entry).permit(:name, :phone, :email, :comments)
    end
  end

  scope :all, -> { current_user.admin? ? Entry.ordered_by_creation_date.all : Entry.ordered_by_creation_date.where(user: current_user) }, default: true
  scope :created, -> { current_user.admin? ? Entry.ordered_by_creation_date.where(status: "created") : Entry.ordered_by_creation_date.where(status: "created", user: current_user) }
  scope :canceled, -> { current_user.admin? ? Entry.ordered_by_creation_date.where(status: "canceled") : Entry.ordered_by_creation_date.where(status: "canceled", user: current_user) }
  scope :sold, -> { current_user.admin? ? Entry.ordered_by_creation_date.where(status: "sold") : Entry.ordered_by_creation_date.where(status: "sold", user: current_user) }
  scope :confirmed, -> { current_user.admin? ? Entry.ordered_by_creation_date.where(status: "confirmed") : Entry.ordered_by_creation_date.where(status: "confirmed", user: current_user) }
  scope :redeemed, -> { current_user.admin? ? Entry.ordered_by_creation_date.where(status: "redeemed") : Entry.ordered_by_creation_date.where(status: "redeemed", user: current_user) }
  scope :general, -> { current_user.admin? ? Entry.ordered_by_creation_date.where(entry_type: "general") : Entry.ordered_by_creation_date.where(entry_type: "general", user: current_user) }
  scope :vip, -> { current_user.admin? ? Entry.ordered_by_creation_date.where(entry_type: "vip") : Entry.ordered_by_creation_date.where(entry_type: "vip", user: current_user) }
  scope :nomad, -> { current_user.admin? ? Entry.ordered_by_creation_date.where(entry_type: "nomad") : Entry.ordered_by_creation_date.where(entry_type: "nomad", user: current_user) }
  scope :premium, -> { current_user.admin? ? Entry.ordered_by_creation_date.where(entry_type: "premium") : Entry.ordered_by_creation_date.where(entry_type: "premium", user: current_user) }
  scope :furama, -> { current_user.admin? ? Entry.ordered_by_creation_date.where(entry_type: "furama") : Entry.ordered_by_creation_date.where(entry_type: "furama", user: current_user) }

  table do
    column :user, sort: :user, header: false do |entry|
      if current_user.admin?
        entry.user
      else
        content_tag(:span, "", style: 'width: 0px;')
      end
    end
    column :code, format: :tags, sort: :code do |entry|
      content_tag(:strong, entry.code)
    end
    column :qr, header: "QR", sort: false do |entry|
      raw entry.qr_code.as_svg(module_size: 1.5)
    end
    column :ticket, sort: false do |entry|
      link_to content_tag(:i, '', class: 'fa fa-download'), entries_admin_download_ticket_path(entry), class: 'btn btn-success', target: '_blank'
    end
    column :status, sort: :status, align: :center do |entry|
      status_tag(entry.status.capitalize, {
        "created" => :info,
        "canceled" => :danger,
        "sold" => :warning,
        "confirmed" => :success,
        "redeemed" => :secondary
        }[entry.status] || :default)
    end
    column :entry_type, sort: :entry_type do |entry|
      {
        "general" => "🎟️ general",
        "vip" => "😎 VIP",
        "nomad" => "💻 Nomad",
        "premium" => "⭐ Premium",
        "furama" => "🛎️ Furama"
      }[entry.entry_type]
    end
    column :customer, sort: :customer do |entry|
      if entry.status == "created"
        nil
      else
        safe_join([
                    content_tag(:strong, entry.name),
                    content_tag(:small, "#{entry.email}", class: 'text-muted hidden-xs'),
                    content_tag(:small, "#{entry.phone}", class: 'text-muted hidden-xs')
                  ], '<br />'.html_safe)
      end
    end
    column :updated_at
    actions do |toolbar, instance, admin|
      entry = instance
      if can_confirm?(entry)
        toolbar.link content_tag(:i, '', class: 'fa fa-credit-card'), admin.path(:confirm, id: entry), method: :post, class: 'btn btn-primary',
        title: 'Confirm payment', data: { toggle: 'tooltip' }
      end
      if can_unconfirm?(entry)
        toolbar.link content_tag(:i, '', class: 'fa fa-credit-card'), admin.path(:unconfirm, id: entry), method: :post, class: 'btn btn-default',
        title: 'Unconfirm payment', data: { toggle: 'tooltip', confirm: 'Are you sure you want to unconfirm this entry? This action is reserved to fix mistakes' }
      end
      if can_cancel?(entry)
        link_to content_tag(:i, '', class: 'fa fa-trash'), admin.path(:cancel, id: entry), method: :post, class: 'btn btn-danger',
        title: 'Cancel this entry permanently', data: { toggle: 'tooltip', confirm: 'Are you sure you want to cancel this entry? This action cannot be undone' }
      end
    end
    
  end

  sort_column(:user) do |collection, order|
    sorted = collection.to_a.sort_by { |o| o.user.email }
    sorted.reverse! if order == :desc
    sorted
  end

  form dialog: true do |entry|
    toolbar(:primary) do |t|
      if can_confirm?(entry)
        link_to admin.path(:confirm, id: instance), method: :post, class: 'btn btn-primary', 
        title: 'Confirm payment', data: { toggle: 'tooltip' } do
          content_tag(:i, '', class: 'fa fa-credit-card')
        end
      end
      if can_unconfirm?(entry)
        link_to admin.path(:unconfirm, id: instance), method: :post, class: 'btn btn-default', 
        title: 'Unconfirm payment', data: { toggle: 'tooltip', confirm: 'Are you sure you want to unconfirm this entry? This action is reserved to fix mistakes' } do
          content_tag(:i, '', class: 'fa fa-credit-card')
        end
      end
    end
    toolbar(:secondary) do |t|
      if can_cancel?(entry)
        link_to admin.path(:cancel, id: instance), method: :post, class: 'btn btn-danger',
        title: 'Cancel this entry permanently', data: { toggle: 'tooltip', confirm: 'Are you sure you want to cancel this entry? This action cannot be undone' } do
          content_tag(:i, '', class: 'fa fa-trash')
        end
      end
    end
    tab :data do
      row do
        col(sm: 4) { static_field :code do
          content_tag(:strong, entry.code, class: 'tag')
        end }
        col(sm: 4) { static_field :entry_type do
          {
            "general" => "🎟️ General",
            "vip" => "😎 VIP",
            "nomad" => "💻 Nomad",
            "premium" => "⭐ Premium",
            "furama" => "🛎️ Furama"
          }[entry.entry_type]
        end }
        col(sm: 4) { static_field :status do
          status_tag(entry.status.capitalize, {
            "created" => :info,
            "canceled" => :danger,
            "sold" => :warning,
            "confirmed" => :success,
            "redeemed" => :secondary
          }[entry.status] || :default)
        end }
        col(sm: 6) { text_field :name, label: "Name *", required: true, disabled: !(current_user.admin? || %w[created sold].include?(entry.status)) }
        col(sm: 6) { text_field :phone, label: "Phone *", required: true, disabled: !(current_user.admin? || %w[created sold].include?(entry.status)) }
        col(sm: 6) do 
          text_field :email, 
                     label: "Email *", 
                     required: true, 
                     type: :email, 
                     disabled: !(current_user.admin? || %w[created sold].include?(entry.status)) 
        end
      end

      if !current_user.admin? && !%w[created sold].include?(entry.status)
        row do
          col(sm: 12) do
            content_tag(:p, "Name, Phone and Email are not editable in the current status.", class: "alert alert-info")
          end
        end
      end
  
      if entry.status == "created"
        row do
          col(sm: 12) do
            content_tag(:p, "Filling in this data will update the status to 'Sold'.", class: "alert alert-warning")
          end
        end
      end

      row do
        col(sm: 12) { text_area :comments }
      end
    end
  
    tab :qr, label: "QR" do
      row do
        col(sm: 4) do
          static_field :code do
            content_tag(:strong, entry.code, class: 'tag')
          end
        end
        col(sm: 4) do
          raw entry.qr_code.as_svg(module_size: 3)
        end
        col(sm: 4) do
          row do
            col(sm: 12) do
              link_to 'Download QR Code', entries_admin_download_qr_code_path(entry), class: 'btn btn-warning', target: '_blank'
            end
            divider
            col(sm: 12) do
              link_to 'Download Ticket', entries_admin_download_ticket_path(entry), class: 'btn btn-warning', target: '_blank'
            end
          end
        end
      end
      divider
      row do
        col(sm: 12) do
          image_tag('general_template.png', alt: 'General Template Image')
        end
      end
    end
  
    tab :log do
      h4 'log'
    end

  end

  search do |query|
    result = if query
      Entry.joins(:user).where("entries.code ILIKE ?
        OR entries.name ILIKE ?
        OR entries.phone ILIKE ?
        OR entries.email ILIKE ?
        OR users.email ILIKE ?
        OR entries.code ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
    else
      Entry.all
    end
    if current_user.admin?
      result
    else
      result.where(user: current_user)
    end
  end
end
