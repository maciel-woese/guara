
module Guara
  	module ActiveCrm
    	class ScheduledContactsController < Guara::BaseController
    		skip_authorization_check

    		include ScheculedsHelper
            include ScheculedContactsHelper
            helper ScheculedContactsHelper

    		def index
    			params[:search] = {} if params[:search].nil?
    			scheduled_customer_group = Scheduled::CustomerGroup.find_by_scheduled_id(params[:scheduled_id])
    			search = prepare_filter_search(params[:search], scheduled_customer_group)
    			
    			@search = Guara::Customer.verify_scheduled(params[:scheduled_id], '=').search(search)
                @search_scheduled = Guara::Customer.verify_scheduled(params[:scheduled_id], '>').search(search)

                @customers_to_register = paginate(@search, params[:page], 3)
                @customers_scheduled = paginate(@search_scheduled)
    		end

            def new
                @contact = Guara::Contact.find(params[:contact_id])
                @scheduled_contact = Scheduled::Contact.new(
                    :contact_id=> params[:contact_id], 
                    :scheduled_id=> params[:scheduled_id]
                )
                render 'new.html.erb', layout: false
            end

            def create
                @scheduled_contact = Scheduled::Contact.new(params[:active_crm_scheduled_contact])
                @scheduled_contact.deal_id = create_deal()

                @scheduled_contact.save
                data = prepare_data_json()
                render :json => {success: true, data: data}
            end

            def ignore_customer_session
                session[:ignored_customers] = [] if session[:ignored_customers].nil?
                session[:ignored_customers] << params[:customer_id] if !session[:ignored_customers].include?(params[:customer_id])
                render :json => {success: true}
            end

            private
            
            def prepare_data_json
                data = @scheduled_contact.attributes
                data["customer_name"] = @scheduled_contact.contact.customer.name
                data["contact_name"] = @scheduled_contact.contact.name
                data["scheduled"] = @scheduled_contact.scheduled.nil? ? '' : @scheduled_contact.scheduled.strftime("%d/%m/%Y %H:%M")
                data["status"] = prepare_span_status(@scheduled_contact)
                return data
            end

            def create_deal
                deal = Guara::ActiveCrm::Scheduled::Deals
                .where(:customer_pj_id=> @scheduled_contact.contact.person_id, :scheduled_id=> params[:scheduled_id]).first
                
                if deal.nil?
                  deal = Guara::ActiveCrm::Scheduled::Deals.create(
                    :customer_pj_id=> @scheduled_contact.contact.person_id, 
                    :date_start=> Time.now, 
                    :scheduled_id=> params[:scheduled_id], 
                    :groups_id=> 9
                  )
                end

                return deal.id
            end

    	end
    end
end