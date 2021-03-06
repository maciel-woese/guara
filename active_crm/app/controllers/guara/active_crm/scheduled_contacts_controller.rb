
module Guara
  	module ActiveCrm
    	class ScheduledContactsController < Guara::BaseController
    		skip_authorization_check

    		include ScheduledsHelper
            include ScheduledContactsHelper
            helper ScheduledContactsHelper

    		def index
    			params[:search] = {} if params[:search].nil?
    			scheduled_customer_group = Scheduled::CustomerGroup.find(params[:scheduled_customer_group_id])
    			search = prepare_filter_search(params[:search], scheduled_customer_group)
    			
    			@search = Guara::Customer.customer_contact(params[:scheduled_customer_group_id]).search(search)
                @search_scheduled = Guara::Customer.customer_scheduled(params[:scheduled_customer_group_id]).search(search)

                @customers_to_register = paginate(@search, params[:page], 40)
                @customers_scheduled = paginate(@search_scheduled)
    		end

            def new
                @contact = Guara::Contact.find(params[:contact_id])
                @scheduled_contact = Scheduled::Contact.new(contact_id: params[:contact_id], user_id: current_user.id)

                @deal = Guara::ActiveCrm::Scheduled::Deals.where(:customer_pj_id=> @contact.person_id, :groups_id=> params[:scheduled_customer_group_id]).first

                render 'new.html.erb', layout: false
            end

            def create
                @scheduled_contact = Scheduled::Contact.new(params[:active_crm_scheduled_contact])
                @scheduled_contact.deal = create_deal(@scheduled_contact.contact.person_id, params[:scheduled_customer_group_id])
                Scheduled::Contact.update_all("enabled = false ", "deal_id = #{@scheduled_contact.deal_id} AND contact_id = #{@scheduled_contact.contact_id}")
                @scheduled_contact.save
                data = prepare_data_json()
                render :json => {success: true, data: data}
            end

            def ignore_customer_session
                session[:ignored_customers] = [] if session[:ignored_customers].nil?
                session[:ignored_customers] << params[:customer_id] if !session[:ignored_customers].include?(params[:customer_id])
                render :json => {success: true}
            end

            def close_negociation
                deal = Scheduled::Deals.where(:customer_pj_id=> params[:customer_id], :groups_id=> params[:customer_group]).first
                deal = create_deal(params[:customer_id], params[:customer_group]) if deal.nil?
                deal.update_attributes(:closed=> true, :date_finish=> Time.now)
                render :json => { success: true}
            end

            private
            
            def prepare_data_json
                data = @scheduled_contact.attributes
                data["customer_name"] = @scheduled_contact.contact.customer.name
                data["customer_id"] = @scheduled_contact.contact.customer.id
                data["contact_name"] = @scheduled_contact.contact.name
                data["scheduled"] = @scheduled_contact.scheduled.nil? ? '' : @scheduled_contact.scheduled.strftime("%d/%m/%Y %H:%M")
                data["status"] = prepare_span_status(@scheduled_contact)
                return data
            end

            def create_deal(customer_id, groups_id)
                deal = Guara::ActiveCrm::Scheduled::Deals
                .where(:customer_pj_id=> customer_id, :groups_id=> groups_id).first
                
                if deal.nil?
                  deal = Guara::ActiveCrm::Scheduled::Deals.create(
                    :customer_pj_id=> customer_id, 
                    :date_start=> Time.now, 
                    :groups_id=> groups_id
                  )
                end

                return deal
            end
    	end
    end
end