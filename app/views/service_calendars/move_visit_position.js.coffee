$(".arm_id_<%= @arm.id %>.move-visits").html("<%= escape_javascript(render :partial => 'move_visit_position', :locals => {:tab => @tab, :arm => @arm, :service_request => @service_request}) %>")
$(".arm_id_<%= @arm.id %>.service_calendar").replaceWith("<%= escape_javascript(render :partial => 'calendar_data', :locals => {:tab => @tab, :arm => @arm, :service_request => @service_request}) %>")