# Explicitly load model components in dependency-friendly order
require 'date'
require_relative 'models/person'
require_relative 'models/accounts'
require_relative 'models/income_sources'
require_relative 'models/household'
require_relative 'models/tax_year'
require_relative 'models/conversion_strategies'
require_relative 'models/annual_planner'
require_relative 'models/life_planner'
require_relative 'models/plan_service'
require_relative 'models/phase_analyzer'

# Load chart data models
require_relative 'models/charts/net_worth_chart'
require_relative 'models/charts/income_tax_chart'

puts "Joyful Retirement Planner models loaded. Now."
