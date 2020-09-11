require 'springcm-sdk'

class Task
  attr_reader :springcm

  def initialize
    @springcm = Springcm::Client.new(SPRINGCM_DATA_CENTER, SPRINGCM_CLIENT_ID, SPRINGCM_CLIENT_SECRET)
  end

  def do
    [
      'Alta Corp',
      'Bellflower',
      'Culver City',
      'Foothills',
      'Hollywood',
      'Los Angeles',
      'Newport',
      'Norwalk',
      'Van Nuys'
    ].each { |hospital|
      update_hospital(hospital)
    }
  end

  def update_hospital(hospital)
    folder = springcm.folder(path: "/PMH/Alta Hospitals/Human Resources/#{hospital}")
    secgroup = load_group_for(hospital)
    puts "Located security group for #{hospital}"
    [
      'Active',
      'Terminated'
    ].each { |name|
      repo = springcm.folder(path: "#{folder.path}/#{name}")
      update_employees_in(repo, secgroup)
    }
  end

  def load_group_for(hospital)
    groups = springcm.groups(limit: 1000)
    while !groups.nil?
      res = groups.items.filter { |group|
        group.name == "PMH Employee Health - #{hospital}"
      }
      return res.first if res.one?
      groups = groups.next
    end
  end

  def update_employees_in(repo, secgroup)
    folders = repo.folders(limit: 1000)
    while !folders.nil?
      folders.items.each { |folder|
        path = "#{repo.path}/#{folder.name}"
        ehf = springcm.folder(path: "#{path}/Employee Health")
        if !ehf.nil?
          puts "Updating security for #{path}"
          ehf.update_security(group: secgroup, access: :view).await!
        else
          puts "Unable to locate employee health folder for #{path}"
        end
      }
      folders = folders.next
    end
  end
end

Task.new.do
