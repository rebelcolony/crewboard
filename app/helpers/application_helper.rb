module ApplicationHelper
  def usage_bar_color(percent)
    if percent >= 100
      "progress-bar-warning"
    elsif percent >= 80
      "progress-bar-accent"
    else
      "progress-bar-success"
    end
  end
end
