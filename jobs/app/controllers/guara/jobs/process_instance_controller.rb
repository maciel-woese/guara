
module Guara
  module Jobs
    class ProcessInstanceController < Guara::BaseController
      load_and_authorize_resource :process_instance, :class => "Guara::Jobs::ProcessInstance"
      load_and_authorize_resource :custom_process, :class => "Guara::Jobs::CustomProcess"

      helper CrudHelper

      attr_accessor :embedded

      def index
        @search = ProcessInstance.search(params[:search])
        if class_exists?("Ransack")
            @process_instance = @search.result().paginate(page: params[:page], :per_page => 10)
        else
            @process_instance = @search.paginate(page: params[:page], :per_page => 10)
        end
        params[:search] = {} if params[:search].nil?
      end

      def new
        @custom_process = Vacancy.custom_process
        @process_instance = ProcessInstance.new
        
        @process_instance.update_attributes({
          :process_id=> @custom_process.id,
          :date_start=> Time.now.to_s(:db),
          :user_using_process=> current_user.id,
          :state=> @custom_process.step_init
        })

        if @process_instance.save
          redirect_to edit_process_instance_path(@process_instance)
        else
          render :index
        end
      end

      def alter_state_process_instance
        @process_instance = ProcessInstance.find params[:id]
        @process_instance.update_attributes :state=> params[:state]
        @process_instance.save

        redirect_to edit_process_instance_path(params[:id])
      end

      def edit
        @process_instance = ProcessInstance.find params[:id]
        
        if params[:edit_step].nil?
          @current_step = @process_instance.step
        else
          @current_step = Step.find params[:edit_step]
        end
        
        @grouped_column_attrs_current_step = load_grouped_columned_attrs(@current_step)
        @grouped_column_attrs_step_init    = load_grouped_columned_attrs(@process_instance.custom_process.step)
      end
      
      def load_grouped_columned_attrs(step)
        grouped_attrs = step.attrs.group_by(&:group).sort()
        
        grouped_column_attrs = {}
        
        grouped_attrs.each do |group, attrs|
          grouped_column_attrs[group] = attrs.group_by(&:column)
        end
        
        if grouped_column_attrs.include? ''
          grouped_column_attrs[:default] = grouped_column_attrs['']
          grouped_column_attrs.delete('')
        end
        return grouped_column_attrs
      end

      def create_step_instance_attrs
        @step_instance_attrs.each do |key, value|
          step_attr_val = {
            :process_instance_id=> params[:id], 
            :step_attr_id=> key, 
            :step_id=>@step_id, 
            :value=> nil
          }

          if value.class == Array
            @step_instance_attr = StepInstanceAttr.create(step_attr_val)
            attrs.each do |attr|
              @step_instance_attr.step_instance_attr_multis.create :value=> attr
            end
          else
            step_attr_val[:value] = value
            @step_instance_attr = StepInstanceAttr.create(step_attr_val)
          end
        end
      end

      def update
        @step_instance_attrs = params[:step_instance_attrs]
        @step_id = @step_instance_attrs.delete(:step_id)
        StepInstanceAttr.delete_all("step_id = #{@step_id}")

        create_step_instance_attrs()
        set_next_step_to_process_instance()

        redirect_to process_instance_show_step_path(:id=> params[:id], :edit_step=> @step_id)
      end

      def load_next_step_to_process_instance
        @process_instance = ProcessInstance.find params[:id]
        @next_step = @process_instance.step.next
        @next_step_valid = StepAttr.where(:step_id=> @next_step).count()
      end

      def set_next_step_to_process_instance
        load_next_step_to_process_instance()

        if @next_step.nil? or @next_step_valid == 0
          @process_instance.update_attributes :date_finish=> Time.now.to_s(:db)
          @process_instance.save
        else
          @process_instance.update_attributes :state=> @next_step
          @process_instance.save
        end 
      end

      def show_step
        edit
      end
      
      def show
        @process_instance = ProcessInstance.find params[:id]
        @grouped_column_attrs_step_init = load_grouped_columned_attrs(@process_instance.custom_process.step)
        @grouped_column_attrs_current_step = load_grouped_columned_attrs(@process_instance.step)
        @step_order = @process_instance.steps_previous_current
      end

      ##DEPRECATED
      def get_step_attr_cache(step_attrs, step_attr_id)
        step_attrs.each do |a|
          return a if a.id == step_attr_id
        end
      end

      #DEPRECATED
      def attr_values(step_attrs, step_instance_attrs)
        @attr_vals = {}
        step_attrs.each do |s|
          @attr_vals[s.id] = ""
        end

        step_instance_attrs.each do |a|
          if a.value.nil?
            @temp = []
            a.step_instance_attr_multis.each do |s|
              @temp << { :value=> s.value, :step_attr_option=> get_step_attr_cache(step_attrs, a.step_attr_id).options }
            end
            @attr_vals[a.step_attr_id] = @temp

          else
            @attr_vals[a.step_attr_id] = a.value
          end  
        end

        return @attr_vals
      end

      #DEPRECATED
      def get_columns(steps_attrs)
        @columns = {}
        steps_attrs.each do |s|
          @columns[s.column] = [] if @columns[s.column].nil?
          @columns[s.column] << s
        end

        return @columns
      end
      
      #DEPRECATED
      def load_step_init
        get_step_init_and_steps_order_and_step_resume(@process_instance, true, false, true)
        @columns = get_columns(@step_attrs)
        @vals    = attr_values(@step_attrs, @step_init.step_attrs_vals(params[:id]))
      end
      
      ##DEPRECATED
      def get_step_init_and_steps_order_and_step_resume(process_instance, step_init=false, step_order=false, step_attrs=false)
        @step_init  = process_instance.step_init if step_init == true
        @step_order = process_instance.steps_previous_current if step_order == true
        @step_attrs = @step_init.step_attrs_resume if step_attrs == true
      end
    
    end
  end
end

