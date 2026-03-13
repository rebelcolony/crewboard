puts "Seeding CrewBoard..."

# Clean up the placeholder account created by the migration backfill
Account.where(name: "Default Account").reject { |a| a.managers.any? || a.projects.any? || a.crew_members.any? }.each(&:destroy)

# Account
account = Account.find_or_create_by!(name: "Aberdeen Offshore Inspections") do |a|
  a.subdomain = "aberdeen"
end
puts "Account: #{account.name}"

# Manager account (super admin)
manager = Manager.find_or_create_by!(email_address: "admin@crewboard.com") do |m|
  m.password = "password123"
  m.password_confirmation = "password123"
  m.account = account
  m.super_admin = true
end
# Ensure existing manager has correct account and admin status
manager.update!(account: account, super_admin: true) unless manager.account == account
puts "Manager: admin@crewboard.com / password123 (super_admin: true)"

# Projects — offshore inspection scenarios
projects_data = [
  {
    name: "Forties Alpha Inspection",
    description: "Annual structural integrity inspection of Forties Alpha platform. Focus on subsea pipelines and riser systems.",
    location: "North Sea — Forties Field",
    status: :in_progress,
    progress: 65,
    start_date: Date.new(2026, 2, 1),
    target_end_date: Date.new(2026, 4, 15)
  },
  {
    name: "Brent Delta Decommissioning",
    description: "Phase 2 decommissioning survey. Topside removal preparation and environmental assessment.",
    location: "North Sea — Brent Field",
    status: :in_progress,
    progress: 30,
    start_date: Date.new(2026, 1, 15),
    target_end_date: Date.new(2026, 6, 30)
  },
  {
    name: "Buzzard Platform NDT Survey",
    description: "Non-destructive testing of critical welds and pressure vessels across all decks.",
    location: "North Sea — Buzzard Field",
    status: :not_started,
    progress: 0,
    start_date: Date.new(2026, 4, 1),
    target_end_date: Date.new(2026, 5, 15)
  },
  {
    name: "CATS Pipeline Survey",
    description: "Central Area Transmission System pipeline integrity survey from Everest to Teesside.",
    location: "Central North Sea",
    status: :in_progress,
    progress: 80,
    start_date: Date.new(2025, 11, 1),
    target_end_date: Date.new(2026, 3, 31)
  },
  {
    name: "Clair Ridge Coating Inspection",
    description: "Anti-corrosion coating assessment on jacket structure legs and bracing.",
    location: "West of Shetland",
    status: :on_hold,
    progress: 15,
    start_date: Date.new(2026, 3, 1),
    target_end_date: Date.new(2026, 5, 1)
  },
  {
    name: "Elgin-Franklin Safety Systems",
    description: "Fire and gas detection system certification. Includes deluge and sprinkler inspections.",
    location: "Central North Sea — Elgin-Franklin",
    status: :completed,
    progress: 100,
    start_date: Date.new(2025, 10, 1),
    target_end_date: Date.new(2026, 1, 31)
  },
  {
    name: "Moray East Wind Farm",
    description: "Foundation inspection of offshore wind turbine monopiles. Scour protection assessment.",
    location: "Moray Firth",
    status: :in_progress,
    progress: 45,
    start_date: Date.new(2026, 2, 15),
    target_end_date: Date.new(2026, 7, 30)
  },
  {
    name: "St Fergus Terminal Review",
    description: "Onshore terminal pipework and vessel inspection. Includes CP system survey.",
    location: "St Fergus, Aberdeenshire",
    status: :not_started,
    progress: 0,
    start_date: Date.new(2026, 5, 1),
    target_end_date: Date.new(2026, 6, 15)
  }
]

projects = projects_data.map do |data|
  Project.find_or_create_by!(name: data[:name]) do |p|
    p.assign_attributes(data)
    p.account = account
  end
end
puts "Created #{projects.size} projects"

# Crew members — offshore inspection roles
crew_data = [
  { name: "Callum MacLeod", role: "Lead Inspector" },
  { name: "Fiona Stewart", role: "Lead Inspector" },
  { name: "Gregor Murray", role: "NDT Technician" },
  { name: "Isla Campbell", role: "NDT Technician" },
  { name: "Hamish Fraser", role: "NDT Technician" },
  { name: "Eilidh Robertson", role: "Rope Access Technician" },
  { name: "Ewan Mackenzie", role: "Rope Access Technician" },
  { name: "Morag Henderson", role: "Coating Inspector" },
  { name: "Lachlan Reid", role: "Coating Inspector" },
  { name: "Skye Anderson", role: "Mechanical Inspector" },
  { name: "Rory Campbell", role: "Mechanical Inspector" },
  { name: "Ailsa Dunbar", role: "Electrical Inspector" },
  { name: "Blair Thomson", role: "Structural Engineer" },
  { name: "Catriona Kerr", role: "Structural Engineer" },
  { name: "Douglas Watt", role: "Subsea Inspector" },
  { name: "Faye Morrison", role: "Subsea Inspector" },
  { name: "Gordon Black", role: "Piping Inspector" },
  { name: "Heather Milne", role: "Safety Coordinator" },
  { name: "Iain Ross", role: "ROV Pilot" },
  { name: "Jenny Sinclair", role: "ROV Pilot" },
  { name: "Kenny Matheson", role: "Welding Inspector" },
  { name: "Lorna Sutherland", role: "QA/QC Manager" },
  { name: "Malcolm Craig", role: "Diving Supervisor" },
  { name: "Niamh Gallagher", role: "CP Technician" },
  { name: "Owen Paterson", role: "Data Analyst" }
]

crew_members = crew_data.map do |data|
  CrewMember.find_or_create_by!(name: data[:name]) do |c|
    c.role = data[:role]
    c.email = "#{data[:name].downcase.gsub(' ', '.')}@crewboard.com"
    c.account = account
  end
end
puts "Created #{crew_members.size} crew members"

# Assign most crew to projects, leave some unassigned
assignments = {
  "Forties Alpha Inspection" => [ "Callum MacLeod", "Gregor Murray", "Eilidh Robertson", "Skye Anderson" ],
  "Brent Delta Decommissioning" => [ "Fiona Stewart", "Blair Thomson", "Douglas Watt", "Heather Milne" ],
  "CATS Pipeline Survey" => [ "Hamish Fraser", "Faye Morrison", "Iain Ross" ],
  "Clair Ridge Coating Inspection" => [ "Morag Henderson", "Lachlan Reid" ],
  "Moray East Wind Farm" => [ "Catriona Kerr", "Ewan Mackenzie", "Jenny Sinclair", "Niamh Gallagher" ],
  "Elgin-Franklin Safety Systems" => [ "Ailsa Dunbar", "Rory Campbell", "Gordon Black" ]
}

assignments.each do |project_name, member_names|
  project = Project.find_by!(name: project_name)
  member_names.each do |name|
    member = CrewMember.find_by!(name: name)
    member.update!(project: project)
  end
end

unassigned = CrewMember.where(project_id: nil).pluck(:name)
puts "Assigned crew to projects. #{unassigned.size} unassigned: #{unassigned.join(', ')}"

puts "Done! Sign in at admin@crewboard.com / password123"
