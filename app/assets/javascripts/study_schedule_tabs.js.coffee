$(document).ready ->
  $(document).on 'click', '.schedule-tabs a', (e) ->
    e.preventDefault()

    url = $(this).attr("data-url")
    href = this.hash
    pane = $(this)

    # ajax load from data-url
    $.ajax
      type: 'GET'
      url: url
      dataType: 'html'
      success: (data) ->
        $(href).html data
        pane.tab('show')

  # load first tab content
  refresh_study_schedule()
