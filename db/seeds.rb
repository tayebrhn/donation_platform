[
  {
    title: "Build a School Library",
    description: "Help provide books and a safe reading space for local students.",
    goal_amount_cents: 1_000_000,
    currency: "USD",
    status: "active"
  },
  {
    title: "Create a Community Garden",
    description: "Turn an unused schoolyard into a garden and outdoor classroom.",
    goal_amount_cents: 500_000,
    currency: "USD",
    status: "draft"
  }
].each do |attributes|
  Project.find_or_initialize_by(title: attributes[:title]).update!(attributes)
end

if ENV["ADMIN_EMAIL"].present? && ENV["ADMIN_PASSWORD"].present?
  admin = User.find_or_initialize_by(email: ENV["ADMIN_EMAIL"].downcase)
  admin.assign_attributes(name: ENV.fetch("ADMIN_NAME", "Platform Administrator"), role: "admin")
  admin.password = ENV["ADMIN_PASSWORD"] if admin.new_record?
  admin.save!
end
