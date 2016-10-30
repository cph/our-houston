module ReportsHelper

  def sprint_task_css(sprint, task)
    return "success" if task.completed_during?(sprint)
    return "failure" if sprint.completed?
    "todo"
  end

  def arc(options={}) # ported from D3
    π = Math::PI
    τ = 2 * π
    d3_svg_arcOffset = -τ / 4
    d3_svg_arcMax = τ - 1e-6
    r1 = options.fetch(:outer_radius, 30)
    r0 = options.fetch(:inner_radius, r1 / 2)
    a0 = options.fetch(:start_angle, 0) * τ / 360 + d3_svg_arcOffset
    a1 = options.fetch(:end_angle, 360) * τ / 360 + d3_svg_arcOffset
    if a1 < a0
      da = a0
      a0 = a1
      a1 = da
    end
    da = a1 - a0
    df = da < π ? "0" : "1"
    c0 = Math.cos(a0)
    s0 = Math.sin(a0)
    c1 = Math.cos(a1)
    s1 = Math.sin(a1)
    if da >= d3_svg_arcMax
      if r0
        "M0,#{r1}A#{r1},#{r1} 0 1,1 0,#{-r1}A#{r1},#{r1} 0 1,1 0,#{r1}M0,#{r0}A#{r0},#{r0} 0 1,0 0,#{-r0}A#{r0},#{r0} 0 1,0 0,#{r0}Z"
      else
        "M0,#{r1}A#{r1},#{r1} 0 1,1 0,#{-r1}A#{r1},#{r1} 0 1,1 0,#{r1}Z"
      end
    else
      if r0
        "M#{r1 * c0},#{r1 * s0}A#{r1},#{r1} 0 #{df},1 #{r1 * c1},#{r1 * s1}L#{r0 * c1},#{r0 * s1}A#{r0},#{r0} 0 #{df},0 #{r0 * c0},#{r0 * s0}Z"
      else
        "M#{r1 * c0},#{r1 * s0}A#{r1},#{r1} 0 #{df},1 #{r1 * c1},#{r1 * s1}L0,0Z"
      end
    end
  end

  def arc_tick(options={})
    π = Math::PI
    τ = 2 * π
    d3_svg_arcOffset = -τ / 4
    d3_svg_arcMax = τ - 1e-6
    r0 = options.fetch(:inner_radius, 30)
    r1 = options.fetch(:outer_radius, r0 + 4)
    a0 = options.fetch(:angle, 0) * τ / 360 + d3_svg_arcOffset
    c0 = Math.cos(a0)
    s0 = Math.sin(a0)
    "M#{r0 * c0},#{r0 * s0}L#{r1 * c0},#{r1 * s0}Z"
  end

  def cool_avatar(user, size: 200)
    <<-HTML.html_safe
    <svg width="#{size}" height="#{size}" class="cool-avatar">
      <defs>
        <radialGradient id="Gradient" cx="33%" cy="33%" r="67%">
          <stop offset="0.75" style="stop-color:rgb(255,255,255)" />
          <stop offset="1.00" style="stop-color:rgb(0,0,0)" />
        </radialGradient>
        <mask id="mask">
          <path d="M#{size},#{0.75 * size}c0,#{0.13807 * size}-#{0.111935 * size},#{0.25 * size}-#{0.25 * size},#{0.25 * size}H0V0h#{size}L#{size},#{0.75 * size}z" fill="url(#Gradient)"/>
        </mask>
        <filter id="greyscale">
          <feColorMatrix type="matrix" values="0.3333 0.3333 0.3333 0 0
            0.3333 0.3333 0.3333 0 0
            0.3333 0.3333 0.3333 0 0
            0 0 0 1 0" />
        </filter>
      </defs>
      <image xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#{gravatar_url(user.email, size: size * 2)}" width="#{size}" height="#{size}" mask="url(#mask)" filter="url(#greyscale)"></image>
    </svg>
    HTML
  end

end
