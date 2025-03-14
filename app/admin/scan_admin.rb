Trestle.admin(:scan, model: false) do
  menu do
    item :scan, icon: "fa fa-qrcode"
  end

  controller do
    def index
      if params[:code].present?
        @scanned_code = params[:code].tr("'", "-") # Replace ' with -
        @entry = Entry.find_by(code: @scanned_code)

        if @entry
          @entry.add_scan
        end
      end
    end
  end
end
