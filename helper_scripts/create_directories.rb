require 'byebug'


def create_directories

  range = "16"
  array = ['dilutive-conceptual', 'dilutive-cpa', 'dilutive-computational', 'eps-conceptual', 'eps-computational', 'eps-cpa', 'ifrs']


  range.each do |no|
    folder = File.join(Dir.home, "Sites/Work/ACC 541/data/ch16")

    array.each do | subfolder_name|
      Dir.mkdir(File.join(folder, subfolder_name))
    end
  end


end

create_directories
