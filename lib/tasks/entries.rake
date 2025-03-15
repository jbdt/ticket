namespace :entries do
  desc "Reset all entries from entries.json"
  task reset: :environment do
    puts "Deleting all entries..."
    Entry.destroy_all

    file_path = Rails.root.join('entries.json')
    entries_json = File.read(file_path)
    entries = JSON.parse(entries_json)

    puts "Restoring entries from JSON..."
    entries.each do |entry|
      Entry.create!(entry.except("id", "created_at", "updated_at"))
    end

    puts "Entries reset complete!"
  end
end
