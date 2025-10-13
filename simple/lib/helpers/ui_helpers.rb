module Foresight
  module Simple
    module UIHelpers
      # Render an edge-anchored toggle panel (Stimulus controller: toggle-panel)
      # Examples:
      #   == togglepanel(:left, "Hello, world!", label: "Hello")
      #   == togglepanel(:top, label: "Tools", collapsed: "2rem", expanded: "50vh") do
      #        p Inside content
      #      end
      # 
      # Nesting: Panels automatically support nesting using CSS Grid
      #   == toggleleft label: "Outer" do
      #     == toggleright label: "Inner"
      #       p Nested content
      #     p Main content
      # 
      # Options:
      #   label: "Tools"                      # visible label in panel
      #   collapsed: "2rem", expanded: "30vh" # per-instance size overrides
      #   nested: true                        # DEPRECATED: handled automatically by CSS Grid
      #   offset: "2rem"                      # DEPRECATED: handled automatically by CSS Grid
      def togglepanel(position = :left, content = nil, label: nil, collapsed: nil, expanded: nil, nested: nil, offset: nil, icon: nil, icons_only: nil, &block)
        locals = {
          position: (position || :left).to_s,
          label: label,
          collapsed: collapsed,
          expanded: expanded,
          nested: nested,
          offset: offset,
          icon: icon,
          icons_only: icons_only,
          content: content,
          has_block: !!block
        }
        slim :'helpers/togglepanel', locals: locals, &block
      end

      # Aliases for convenience
      # Usage:
      #   == toggletop "Hello", label: "Top"
      #   == togglebottom(label: "Bottom") do
      #        p Content
      #      end
      def toggletop(content = nil, label: nil, collapsed: nil, expanded: nil, nested: nil, offset: nil, icon: nil, icons_only: nil, &block)
        togglepanel(:top, content, label: label, collapsed: collapsed, expanded: expanded, nested: nested, offset: offset, icon: icon, icons_only: icons_only, &block)
      end

      def togglebottom(content = nil, label: nil, collapsed: nil, expanded: nil, nested: nil, offset: nil, icon: nil, icons_only: nil, &block)
        togglepanel(:bottom, content, label: label, collapsed: collapsed, expanded: expanded, nested: nested, offset: offset, icon: icon, icons_only: icons_only, &block)
      end

      def toggleleft(content = nil, label: nil, collapsed: nil, expanded: nil, nested: nil, offset: nil, icon: nil, icons_only: nil, &block)
        togglepanel(:left, content, label: label, collapsed: collapsed, expanded: expanded, nested: nested, offset: offset, icon: icon, icons_only: icons_only, &block)
      end

      def toggleright(content = nil, label: nil, collapsed: nil, expanded: nil, nested: nil, offset: nil, icon: nil, icons_only: nil, &block)
        togglepanel(:right, content, label: label, collapsed: collapsed, expanded: expanded, nested: nested, offset: offset, icon: icon, icons_only: icons_only, &block)
      end
    end
  end
end
