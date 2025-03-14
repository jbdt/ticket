Trestle.resource(:users, model: User, scope: Auth) do
  require 'zip'

  menu do
    if current_user.admin?
      item :users, icon: "fas fa-users",
      badge: { text: User.count },
      priority: 2
    end
  end

  routes do
    get :download_all_tickets
    get :download_general_tickets
    get :download_vip_tickets
    get :download_nomad_tickets
    get :download_premium_tickets
    get :download_furama_tickets
  end

  controller do
    def index
      unless current_user.admin?
        flash[:error] = "You are not authorized to view users."
        redirect_to entries_admin_index_path
      end
    end

    def create_entries(params, user)
      new_entries = {
        general_count: params["general"].to_i,
        vip_count: params["vip"].to_i,
        nomad_count: params["nomad"].to_i,
        premium_count: params["premium"].to_i,
        furama_count: params["furama"].to_i,
      }
    
      new_entries[:general_count].times { Entry.create(entry_type: "general", user: user) }
      new_entries[:vip_count].times { Entry.create(entry_type: "vip", user: user) }
      new_entries[:nomad_count].times { Entry.create(entry_type: "nomad", user: user) }
      new_entries[:premium_count].times { Entry.create(entry_type: "premium", user: user) }
      new_entries[:furama_count].times { Entry.create(entry_type: "furama", user: user) }

      new_entries
    end

    def update
      user = User.find(params[:id])

      if params["create_entries"]
        created_entries = create_entries(params['user'], user)
        if created_entries.values.sum.zero?
          flash[:error] = "No entries added"
        else
          flash[:message] = {title: 'New entries created successfully.', message: "
          🎟️ General: #{created_entries[:general_count]} |
          😎 VIP: #{created_entries[:vip_count]} |
          💻 Nomad: #{created_entries[:nomad_count]} |
          ⭐ Premium: #{created_entries[:premium_count]} |
          🛎️ Furama: #{created_entries[:furama_count]}
          "}
        end
        redirect_to edit_auth_users_admin_path(user.id)
      else
        super
      end
    end

    def download_all_tickets
      download_tickets
    end
    def download_general_tickets
      download_tickets("general")
    end
    def download_vip_tickets
      download_tickets("vip")
    end
    def download_nomad_tickets
      download_tickets("nomad")
    end
    def download_premium_tickets
      download_tickets("premium")
    end
    def download_furama_tickets
      download_tickets("furama")
    end

    def download_tickets(entry_type=nil)
      user = User.find(params[:auth_users_admin_id])
      entries = Entry.where(user: user)
      if entry_type
        entries = entries.where(entry_type: entry_type)
      end
    
      tickets_pending = false
      entries.each do |entry|
        ticket_path = Rails.root.join('tmp', 'tickets', "ticket_#{entry.code}.png")
        unless File.exist?(ticket_path)
          tickets_pending = true
          break
        end
      end
    
      if tickets_pending
        flash[:error] = "Tickets are still being generated. Please try again in 5 minutes."
        redirect_to edit_auth_users_admin_path(user.id)
      else
        zipfile = Tempfile.new(['tickets', '.zip'])
        Zip::File.open(zipfile.path, Zip::File::CREATE) do |zip|
          entries.each do |entry|
            ticket_path = Rails.root.join('tmp', 'tickets', "ticket_#{entry.code}.png")
    
            if File.exist?(ticket_path)
              zip.add("ticket_#{entry.code}.png", ticket_path)
            end
          end
        end
    
        send_file zipfile.path, type: 'application/zip', disposition: 'attachment', filename: "#{user.email}_#{entry_type || "all" }_tickets.zip"
      end
    end
    
  end

  scope :all, -> { User.ordered_by_creation_date }, default: true

  table do
    column :email, link: true
    column :alias_code
    column :admin
    actions do |a|
      a.delete unless a.instance == current_user
    end
  end

  form do |user|
    def status_count_table(entry_type)
      concat(content_tag(:table, class: "table table-bordered table-striped") do
        concat(content_tag(:tbody) do
          Entry.statuses.keys.each do |status|
            concat(content_tag(:tr) do
              concat(content_tag(:td) do
                status_tag(status.capitalize, {
                  "created" => :info,
                  "canceled" => :danger,
                  "sold" => :warning,
                  "confirmed" => :success,
                  "redeemed" => :secondary
                }[status] || :default)
              end)
              concat(content_tag(:td, @entries_count_by_type_and_status[[entry_type, status]] || 0, class: "text-center"))
            end)
          end
        end)
      end)
    end
    tab :create do
      @entries_count_by_type_and_status = Entry.where(user: user)
      .group(:entry_type, :status)
      .count

      row do
        col(sm: 12) { 
          h2 user.email
        }
      end

      row do
        col(sm: 12) { 
          h5 "Fills with the number of entries to generate for the user."
        }
      end


      row do
        Entry.entry_types.keys.each do |entry_type|
          col(sm: 3
          ) { 
            row { text_field entry_type.to_sym, type: "number", min: 0, step: 1, value: nil }
            row { col { status_count_table(entry_type) } }
          }
        end
      end
    
      row do
        col(sm: 12) {
          submit 'Create Entries', class: 'btn btn-primary', name: 'create_entries'
        }
      end
    end

    tab :download do
      row do
        col(sm: 12) { 
          h2 user.email
        }
      end
      
      row do
        col {
          link_to 'Download 🎟️ All Tickets', auth_users_admin_download_all_tickets_path(user), class: 'btn btn-success', target: '_blank'
        }
        col {
          link_to 'Download 🎟️ General Tickets', auth_users_admin_download_general_tickets_path(user), class: 'btn btn-primary', target: '_blank'
        }
        col {
          link_to 'Download 😎 VIP Tickets', auth_users_admin_download_vip_tickets_path(user), class: 'btn btn-primary', target: '_blank'
        }
        col {
          link_to 'Download 💻 Nomad Tickets', auth_users_admin_download_nomad_tickets_path(user), class: 'btn btn-primary', target: '_blank'
        }
        col {
          link_to 'Download ⭐ Premium Tickets', auth_users_admin_download_premium_tickets_path(user), class: 'btn btn-primary', target: '_blank'
        }
        col {
          link_to 'Download 🛎️ Furama Tickets', auth_users_admin_download_furama_tickets_path(user), class: 'btn btn-primary', target: '_blank'
        }
      end
    end

    tab :details do
      row do
        col(sm: 12) { 
          h2 user.email
        }
      end

      row do
        col(sm: 6) { text_field :email, required: true, type: :email }
        col(sm: 6) { text_field :alias_code, required: true }
      end
      
      row do
        col(sm: 6) { check_box :admin }
      end
    
      row do
        col(sm: 6) { password_field :password }
        col(sm: 6) { password_field :password_confirmation }
      end

      row do
        col(sm: 12) {
          submit 'Save Details', class: 'btn btn-success'
        }
      end
    end
  
    sidebar do
      total_entries = user.entries.count
      entries_by_type = user.entries.group(:entry_type).count
      order_type = ["general", "vip", "nomad", "premium", "furama"]
      entries_by_type = order_type.each_with_object({}) do |key, result|
        result[key] = entries_by_type[key]
      end
      entries_by_status = user.entries.group(:status).count
      order_status = ["created", "sold", "confirmed", "redeemed", "canceled"]
      entries_by_status = order_status.each_with_object({}) do |key, result|
        result[key] = entries_by_status[key]
      end
    
      concat(content_tag(:h2, "Entries Statistics"))
  
      concat(content_tag(:p, "Total entries: #{total_entries}", class: "text-primary font-weight-bold"))
  
      concat(content_tag(:h5, "Entries by Type"))
      concat(content_tag(:table, class: "table table-bordered table-striped") do
        concat(content_tag(:thead) do
          concat(content_tag(:tr) do
            concat(content_tag(:th, "Type"))
            concat(content_tag(:th, "Count", class: "text-center"))
          end)
        end)
        concat(content_tag(:tbody) do
          entries_by_type.each do |type, count|
            concat(content_tag(:tr) do
              concat(content_tag(:td) do
                {
                  "general" => "🎟️ General",
                  "vip" => "😎 VIP",
                  "nomad" => "💻 Nomad",
                  "premium" => "⭐ Premium",
                  "furama" => "🛎️ Furama"
                }[type] || type.capitalize
              end)
              concat(content_tag(:td, count || 0, class: "text-center"))
            end)
          end
        end)
      end)
  
      concat(content_tag(:h5, "Entries by Status"))
      concat(content_tag(:table, class: "table table-bordered table-striped") do
        concat(content_tag(:thead) do
          concat(content_tag(:tr) do
            concat(content_tag(:th, "Status"))
            concat(content_tag(:th, "Count", class: "text-center"))
          end)
        end)
        concat(content_tag(:tbody) do
          entries_by_status.each do |status, count|
            concat(content_tag(:tr) do
              concat(content_tag(:td) do
                status_tag(status.capitalize, {
                  "created" => :info,
                  "canceled" => :danger,
                  "sold" => :warning,
                  "confirmed" => :success,
                  "redeemed" => :secondary
                }[status] || :default)
              end)
              concat(content_tag(:td, count || 0, class: "text-center"))
            end)
          end
        end)
      end)
    end
  end
  
  params do |params|
    params.require(:user).except(:general, :vip, :nomad, :premium, :furama).permit(
      :email, 
      :alias_code, 
      :admin, 
      :password, 
      :password_confirmation
    )
  end
  
end
