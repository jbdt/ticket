User.create(email: "alex@danang365.com", password: "123123123", alias_code: "DAN", admin: true)
User.create(email: "afc@furamavietnam.com", password: "123123123", alias_code: "FUR", admin: true)
User.create(email: "patakkadanang@gmail.com", password: "123123123", alias_code: "PAT", admin: true)
User.create(email: "tickets@danang365.com", password: "123123123", alias_code: "TIC")


# 2000.times do |i|
#   status = Entry.statuses.keys.sample
#   entry_type = Entry.entry_types.keys.sample

#   entry_attributes = {
#     entry_type: entry_type,
#     user: User.all.sample,
#     status: status
#   }

#   if status != 'created' 
#     entry_attributes[:name] = Faker::Movies::StarWars.character
#     entry_attributes[:phone] = Faker::PhoneNumber.phone_number
#     entry_attributes[:email] = Faker::Internet.email
#   end

#   Entry.create(entry_attributes)

#   puts "#{i} "
# end
