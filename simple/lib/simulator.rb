require 'yaml'

# This is a minimal, joyful implementation of the Simulator to satisfy the
# immediate needs of the frontend. It provides a basic data structure
# for the chart to render.

module Foresight
  class Simulator
    def initialize(profile)
      @profile = profile
    end

    # Runs a basic "do nothing" simulation.
    # In a real implementation, this would involve complex calculations.
    # Here, we just generate plausible-looking sample data.
    def run_do_nothing
      yearly_data = (2024..2054).map.with_index do |year, i|
        {
          year: year,
          aggregate: {
            net_worth: 100000 + (i * 50000) + rand(-10000..10000)
          }
        }
      end
      { yearly: yearly_data, aggregate: { final_net_worth: yearly_data.last[:aggregate][:net_worth] } }
    end
  end
end