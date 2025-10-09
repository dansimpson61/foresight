# slim_pickins/ui_helpers.rb
# A collection of joyful, expressive UI helpers.
# Doctrine: "Expression over Specification"

module SlimPickins
  module UIHelpers
    # Renders an elegant, CSS-driven toggle panel.
    # The panel's layout and interaction with its siblings are handled
    # by CSS, not by complex JavaScript or fragile parameters.
    #
    # == Example
    #   == togglepanel(position: :left, label: "Tools") do
    #     p "Panel content here"
    #
    def togglepanel(position: :left, label: nil, icon: nil, &block)
      # The new helper passes minimal, semantic data to the view.
      # No more layout-specific parameters like `push` or `offset`.
      locals = {
        position: position.to_s,
        label: label,
        icon: icon
      }
      # Render the template using an explicit, unambiguous path.
      # This makes the component self-contained and avoids conflicts
      # with the main application's view paths.
      views_dir = File.expand_path('views', File.dirname(__FILE__))
      slim :togglepanel, views_directory: views_dir, locals: locals, &block
    end

    # Convenient aliases for each position.
    def toggleleft(label: nil, icon: nil, &block)
      togglepanel(position: :left, label: label, icon: icon, &block)
    end

    def toggleright(label: nil, icon: nil, &block)
      togglepanel(position: :right, label: label, icon: icon, &block)
    end

    def toggletop(label: nil, icon: nil, &block)
      togglepanel(position: :top, label: label, icon: icon, &block)
    end

    def togglebottom(label: nil, icon: nil, &block)
      togglepanel(position: :bottom, label: label, icon: icon, &block)
    end
  end
end