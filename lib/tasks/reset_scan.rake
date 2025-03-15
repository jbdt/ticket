namespace :entry do
  desc "Reset scanned attribute for all entries"
  task reset_scan: :environment do
    Entry.update_all(scanned: [])
    puts "All scans have been reset."
  end
end