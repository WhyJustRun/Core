require 'nori'

class ResultListParser
  def initialize(data, event_id)
      @data = data
      @event_id = event_id

      parser = Nori.new(:convert_tags_to => lambda { |tag| tag.snakecase.to_sym })
      @doc = parser.parse(data)

      @using_wjr_ids = uses_wjr_ids?
  end

  def build_name name
    components = []
    components << name[:given]
    components << name[:family]
    components.join(' ')
  end

  def uses_wjr_ids?
    @doc[:result_list][:class_result].each { |class_result|
      class_result[:person_result].each { |person_result|
        id = person_result[:person][:id]
        if id and id.attributes[:type] == 'WhyJustRun'
          return true
        end
      }
    }
  end

  def match_user person_result
    matched_id = nil
    id = person_result[:person][:id]
    name = build_name person_result[:person][:name]
    unless id.nil?
      id = id.to_i
      if User.exists? id: id, name: name
        matched_id = id
      end
    end

    if matched_id.nil?
      matched_id = @name_to_id[name]
    end

    if matched_id.nil?
      matches = User.where name: name
      if matches.length == 1 then
        matched_id = matches[0].id
      elsif matches.length == 0
        create_fake_user
      else

      end
    end
  end

  def build_name_to_id_hash
    existing_courses = Course.where(event_id: @event_id).ids
    existing_results = Result.where('course_id IN (?)', existing_courses).includes(:user)
    @name_to_id = {}
    existing_results.each { |result|
      user = result.user
      if @name_to_id.has_key? user.name and @name_to_id[user.name] != user.id
        # If there are multiple different user's with the same name at the event
        @name_to_id[user.name] = nil
      else
        @name_to_id[user.name] = user.id
      end
    }
  end

  def find_user_conflicts
    build_name_to_id_hash

    @doc[:result_list][:class_result].each { |class_result|
      class_result[:person_result].each { |person_result|
        conflict = match_user person_result
        # TODO
      }
    }
  end
end
