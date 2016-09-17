class LunchMenu

  def self.for(date)
    response = $cphweb09.get "mycph/menu.asp"

    date_query = date.strftime("%A, %B %-d, %Y")
    document = Nokogiri::HTML(response.body)
    date_heading = document.at_css("i[text()=\"#{date_query}\"]")
    return nil if date_heading.nil?

    date_heading.parent.next_element.children
      .select { |e| e.text? }
      .map { |e| e.text }
  end

end
