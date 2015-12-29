module EsrRecordHelper
  def event_image(event)
    html_class = case event.to_s
                 when 'book_extra_earning'
                   'icon-circle-arrow-up'
                 when 'reactivate'
                   'icon-refresh'
                 when 'resolve'
                   'icon-ok'
                 when 'show_all'
                   'icon-list-alt'
                 when 'write_off'
                   'icon-circle-arrow-down'
                 end

    content_tag :span, '', class: html_class
  end
end
