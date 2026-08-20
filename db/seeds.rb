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
