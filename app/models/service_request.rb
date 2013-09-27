class ServiceRequest < ActiveRecord::Base
  audited

  belongs_to :service_requester, :class_name => "Identity", :foreign_key => "service_requester_id"
  belongs_to :protocol
  has_many :sub_service_requests, :dependent => :destroy
  has_many :line_items, :include => [:service], :dependent => :destroy
  has_many :charges, :dependent => :destroy
  has_many :tokens, :dependent => :destroy
  has_many :approvals, :dependent => :destroy
  has_many :documents, :through => :sub_service_requests
  has_many :document_groupings, :dependent => :destroy
  has_many :arms, :through => :protocol

  validation_group :protocol do
    # validates :protocol_id, :presence => {:message => "You must identify the service request with a study/project before continuing."} 
    validate :protocol_page
  end

  validation_group :service_details do
    # TODO: Fix validations for this area
    # validates :visit_count, :numericality => { :greater_than => 0, :message => "You must specify the estimated total number of visits (greater than zero) before continuing.", :if => :has_per_patient_per_visit_services?}
    # validates :subject_count, :numericality => {:message => "You must specify the estimated total number of subjects before continuing.", :if => :has_per_patient_per_visit_services?}
    validate :service_details_forward
  end
  
  validation_group :service_details_back do
    # TODO: Fix validations for this area
    # validates :visit_count, :numericality => { :greater_than => 0, :message => "You must specify the estimated total number of visits (greater than zero) before continuing.", :if => :has_visits?}
    # validates :subject_count, :numericality => {:message => "You must specify the estimated total number of subjects before continuing.", :if => :has_visits?}
    validate :service_details_back
  end

  validation_group :service_calendar do
    #insert group specific validation
    validate :service_calendar_forward
  end

  validation_group :service_calendar_back do
    validate :service_calendar_back
  end

  validation_group :calendar_totals do
  end

  validation_group :service_subsidy do
    #insert group specific validation
  end

  validation_group :document_management do
    #insert group specific validation
  end

  validation_group :review do
    #insert group specific validation
  end
  
  validation_group :obtain_research_pricing do
    #insert group specific validation
  end

  validation_group :confirmation do
    #insert group specific validation
  end

  attr_accessible :protocol_id
  attr_accessible :status
  attr_accessible :service_requester_id
  attr_accessible :notes
  attr_accessible :approved
  attr_accessible :consult_arranged_date
  attr_accessible :pppv_complete_date
  attr_accessible :pppv_in_process_date
  attr_accessible :requester_contacted_date
  attr_accessible :submitted_at
  attr_accessible :line_items_attributes
  attr_accessible :sub_service_requests_attributes

  accepts_nested_attributes_for :line_items
  accepts_nested_attributes_for :sub_service_requests

  alias_attribute :service_request_id, :id

  #after_save :fix_missing_visits

  def protocol_page
    if self.protocol_id.blank?
      errors.add(:protocol_id, "You must identify the service request with a study/project before continuing.")
    else
      if self.has_ctrc_services?
        if self.protocol && self.protocol.has_ctrc_services?(self.id)
          errors.add(:ctrc_services, "SCTR Research Nexus Services have been removed")
        end
      end
    end
  end

  def service_details_back
    service_details_page('back')
  end

  def service_details_forward
    service_details_page('forward')
  end

  def service_details_page(direction)
    if has_per_patient_per_visit_services? and not (direction == 'back' and status == 'first_draft')
      #TODO why is this being called when you try to unset protocol (don't supply one)
      if protocol and protocol.start_date.nil?
        errors.add(:start_date, "You must specify the start date of the study.")
      end

      if protocol and protocol.end_date.nil?
        errors.add(:end_date, "You must specify the end date of the study.")
      end
    end

    arms.each do |arm|
      if arm.valid_visit_count? == false and not (direction == 'back' and status == 'first_draft')
        errors.add(:visit_count, "You must specify the estimated total number of visits (greater than zero) before continuing.")
        break
      end
    end

    arms.each do |arm|
      if arm.valid_subject_count? == false and not (direction == 'back' and status == 'first_draft')
        errors.add(:subject_count, "You must specify the estimated total number of subjects before continuing.")
        break
      end
    end
  end

  def service_calendar_back
    service_calendar_page('back')
  end

  def service_calendar_forward
    service_calendar_page('forward')
  end

  def service_calendar_page(direction)
    return if direction == 'back' and status == 'first_draft'
    self.arms.each do |arm|
      arm.visit_groups.each do |vg|
        if vg.day.blank?
          errors.add(:visit_group, "Please specify a study day for each visit.")
          return
        end
      end
    end
  end

  # Given a service, create a line item for that service and for all
  # services it depends on.
  #
  # Required services will be marked non-optional; optional services
  # will be marked optional.
  #
  # Recursively adds services (e.g. if a service1 depends on service2,
  # and service2 depends on service3, then all 3 services will get line
  # items).
  #
  # Returns an array containing all the line items that were created.
  #
  # Parameters:
  #
  #   service:              the service for which to create line item(s)
  #
  #   optional:             whether the service is optional
  #
  #   existing_service_ids: an array containing the ids of all the
  #                         services that have already been added to the
  #                         service request.  This array will be
  #                         modified to contain the services for the
  #                         newly created line items.
  #
  def create_line_items_for_service(args)
    service = args[:service]
    optional = args[:optional]
    existing_service_ids = args[:existing_service_ids]

    # If this service has already been added, then do nothing
    return if existing_service_ids.include?(service.id)

    line_items = [ ]

    # add service to line items
    line_items << create_line_item(
        service_id: service.id,
        optional: optional,
        quantity: service.displayed_pricing_map.unit_minimum)

    existing_service_ids << service.id

    # add required services to line items
    service.required_services.each do |rs|
      rs_line_items = create_line_items_for_service(
        service: rs,
        optional: false,
        existing_service_ids: existing_service_ids)
      line_items.concat(rs_line_items)
    end

    # add optional services to line items
    service.optional_services.each do |rs|
      rs_line_items = create_line_items_for_service(
        service: rs,
        optional: true,
        existing_service_ids: existing_service_ids)
      rs_line_items.nil? ? line_items : line_items.concat(rs_line_items)
    end

    return line_items
  end

  def create_line_item(args)
    quantity = args.delete(:quantity) || 1
    if line_item = self.line_items.create(args)

      if line_item.service.is_one_time_fee?
        # quantity is only set for one time fee
        line_item.update_attribute(:quantity, quantity)

      else
        # only per-patient per-visit have arms
        self.arms.each do |arm|
          arm.create_line_items_visit(line_item)
        end
      end

      line_item.reload
      return line_item
    else
      return false
    end
  end

  def one_time_fee_line_items
    line_items.map do |line_item|
      line_item.service.is_one_time_fee? ? line_item : nil
    end.compact
  end
  
  def per_patient_per_visit_line_items
    line_items.map do |line_item|
      line_item.service.is_one_time_fee? ? nil : line_item
    end.compact
  end

  def set_visit_page page_passed, arm
    page = case 
           when page_passed <= 0
             1
           when page_passed > (arm.visit_count / 5.0).ceil
             1
           else 
             page_passed
           end
    page
  end

  def service_list is_one_time_fee=nil
    items = []
    case is_one_time_fee
    when nil
      items = line_items
    when true
      items = one_time_fee_line_items
    when false
      items = per_patient_per_visit_line_items
    end

    groupings = {}
    items.each do |line_item|
      service = line_item.service
      name = []
      acks = []
      last_parent = nil
      last_parent_name = nil
      found_parent = false
      service.parents.reverse.each do |parent|
        next if !parent.process_ssrs? && !found_parent
        found_parent = true
        last_parent = last_parent || parent.id
        last_parent_name = last_parent_name || parent.name
        name << parent.abbreviation
        acks << parent.ack_language unless parent.ack_language.blank?
      end
      if found_parent == false
        service.parents.reverse.each do |parent|
          name << parent.abbreviation
          acks << parent.ack_language unless parent.ack_language.blank?
        end
        last_parent = service.organization.id
        last_parent_name = service.organization.name
      end
      
      if groupings.include? last_parent
        g = groupings[last_parent]
        g[:services] << service
        g[:line_items] << line_item
      else
        groupings[last_parent] = {:process_ssr_organization_name => last_parent_name, :name => name.reverse.join(' -- '), :services => [service], :line_items => [line_item], :acks => acks.reverse.uniq.compact}
      end
    end

    groupings
  end

  def has_one_time_fee_services?
    one_time_fee_line_items.count > 0
  end

  def has_per_patient_per_visit_services?
    per_patient_per_visit_line_items.count > 0
  end

  def total_direct_costs_per_patient arms=self.arms
    total = 0.0
    arms.each do |arm|
      total += arm.direct_costs_for_visit_based_service
    end

    total
  end

  def total_indirect_costs_per_patient arms=self.arms
    total = 0.0
    arms.each do |arm|
      total += arm.indirect_costs_for_visit_based_service
    end

    total
  end

  def total_costs_per_patient arms=self.arms
    self.total_direct_costs_per_patient(arms) + self.total_indirect_costs_per_patient(arms)
  end

  def total_direct_costs_one_time line_items=self.line_items
    total = 0.0
    line_items.select {|x| x.service.is_one_time_fee?}.each do |li|
      total += li.direct_costs_for_one_time_fee
    end

    total
  end

  def total_indirect_costs_one_time line_items=self.line_items
    total = 0.0
    line_items.select {|x| x.service.is_one_time_fee?}.each do |li|
      total += li.indirect_costs_for_one_time_fee
    end

    total
  end

  def total_costs_one_time line_items=self.line_items
    self.total_direct_costs_one_time(line_items) + self.total_indirect_costs_one_time(line_items)
  end

  def direct_cost_total line_items=self.line_items
    self.total_direct_costs_one_time(line_items) + self.total_direct_costs_per_patient
  end

  def indirect_cost_total line_items=self.line_items
    self.total_indirect_costs_one_time(line_items) + self.total_indirect_costs_per_patient
  end

  def grand_total line_items=self.line_items
    self.direct_cost_total(line_items) + self.indirect_cost_total(line_items)
  end

  def relevant_service_providers_and_super_users
    identities = []

    self.sub_service_requests.each do |ssr|
      ssr.organization.all_service_providers.each do |sp|
        identities << sp.identity
      end
      ssr.organization.all_super_users.each do |su|
        identities << su.identity
      end
    end

    identities.flatten.uniq
  end

  # Change the status of the service request and all the sub service
  # requests to the given status.
  def update_status(new_status)
    self.update_attributes(status: new_status)

    self.sub_service_requests.each do |ssr|
      ssr.update_attributes(status: new_status) if ['first_draft', 'draft', nil].include?(ssr.status)
    end
  end

  # Make sure that all the sub service requests have an ssr id
  def ensure_ssr_ids
    next_ssr_id = self.protocol.next_ssr_id || 1

    self.sub_service_requests.each do |ssr|
      if not ssr.ssr_id then
        ssr.update_attributes(ssr_id: "%04d" % next_ssr_id)
        next_ssr_id += 1
      end
    end

    self.protocol.update_attributes(next_ssr_id: next_ssr_id)
  end

  def add_or_update_arms
    p = self.protocol
    if p.arms.empty?
      arm = p.arms.create(
        name: 'ARM 1',
        visit_count: 1,
        subject_count: 1,
        new_with_draft: true)
      self.line_items.each do |li|
        arm.create_line_items_visit(li)
      end
    else
      p.arms.each do |arm|
        p.service_requests.each do |sr|
          sr.line_items.each do |li|
            arm.create_line_items_visit(li) if arm.line_items_visits.where(:line_item_id => li.id).empty?
          end
        end
      end
    end
  end

  def should_push_to_epic?
    return self.line_items.any? { |li| li.should_push_to_epic? }
  end

  def has_ctrc_services?
    return self.line_items.any? { |li| li.service.is_ctrc? }
  end

  def remove_ctrc_services
    self.sub_service_requests.each do |ssr|
      ssr.destroy if ssr.ctrc?
    end
  end

  def update_arm_minimum_counts
    self.arms.each do |arm|
      arm.update_minimum_counts
    end
  end

end
