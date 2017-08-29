require 'csv'
require 'sunlight/congress'
require 'erb'
require 'pry'

Sunlight::Congress.api_key = 'e179a6973728c4dd3fb1204283aaccb5'

def clean_zip(zip)
  zip.to_s.rjust(5, '0')[0..4]
end

def phone_num_format(phone_num)
  phone_num.insert(3, '.').insert(7, '.')
end

def check_phone_num(phone)
  phone_num = phone.gsub(/\D/, '').to_s
  return phone_num_format(phone_num) if phone_num.size == 10

  if phone_num.start_with?('1') && phone_num.size == 11
    phone_num_format(phone_num[1..10])
  else
    'N/A'
  end
end

def get_reg_time(time)
  DateTime.strptime(time, '%m/%d/%y %H:%M')
end

def peak_hours(time)
  _2nd = 0.4 * (time.size + 1)
  _3rd = 0.6 * (time.size + 1)
  [time[_2nd], time[_3rd]]
end

def peak_day(time)
  time.max_by { |day| time.count(day) }
end

def legislators_by_zip(zip)
  Sunlight::Congress::Legislator.by_zipcode(zip)
end

def save_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?'output'
  filename = "output/thanks-#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager initialized.'
puts ''

content = CSV.open('full_event_attendees.csv',
                   headers: true,
                   header_converters: :symbol)

template_letter = File.read 'form_letter.erb'
erb_template = ERB.new template_letter
hours = []
week_day = []

content.each do |row|
  id = row[:id]
  name = row[:first_name]
  zip = clean_zip(row[:zipcode])
  phone_num = check_phone_num(row[:homephone])
  hours << reg_time = get_reg_time(row[:regdate]).hour
  week_day << reg_day = get_reg_time(row[:regdate]).strftime("%A")

  legislators = legislators_by_zip(zip)

  form_letter = erb_template.result(binding)

  save_letter(id, form_letter)
end

puts"Peak time for registration is between #{peak_hours(hours.sort)[0]}:00 and #{peak_hours(hours.sort)[1]}:00 hours"
puts "Peak day for registrations is #{peak_day(week_day)}"
