class Event

attr_reader(:id, :name, :participation_type, :max_capacity, :world_record, :sport_id)
  
  def initialize(options)
    @id = options['id'].to_i
    @name = options['name']
    @participation_type = options['participation_type']
    @max_capacity = options['max_capacity'].to_i
    @world_record = options['world_record']
    @sport_id = options['sport_id'].to_i
  end

  def save()
    sql = "INSERT INTO events (name, participation_type, max_capacity, world_record, sport_id) 
    VALUES ('#{@name}', '#{@participation_type}', '#{@max_capacity}', '#{@world_record}', '#{@sport_id}') RETURNING *"
    event = run(sql).first
    result = Event.new(event)
    return result
  end

  def delete()
    sql = "DELETE FROM events WHERE id = '#{@id}'"
    run(sql)
  end

  def update(options)
    sql = "UPDATE events SET name = '#{options['name']},
    participation_type = '#{options['participation_type']},
    max_capacity = '#{options['max_capacity']},
    world_record = '#{options['world_record']},
    sport_id = '#{options['sport_id']}
     WHERE id = '#{@id}'"
    run(sql)
  end

  def add_result(options)
    type = team_or_athlete(options)
    sql = "INSERT INTO #{type}_results (event_id, #{type}_id, measure, position) VALUES
    ('#{@id}', '#{options['participant'].id}', '#{options['measure']}', '#{options['position']}')"
    run(sql)
  end

  def team_or_athlete(options)
    if options['participant'].class == Athlete
      return "athlete"
    else
      return "team"
    end
  end

  def sport()
    sql = "SELECT * FROM sports WHERE id = #{@sport_id}"
    return Sport.map_item(sql)
  end

  def athletes()
    sql = "SELECT athletes.* FROM athletes 
    INNER JOIN athlete_results ON athlete_results.athlete_id = athletes.id 
    WHERE athlete_results.event_id = #{@id}"
    return Athlete.map_items(sql)
  end

  def teams()
    sql = "SELECT teams.* FROM teams 
    INNER JOIN team_results ON team_results.team_id = teams.id 
    WHERE team_results.event_id = #{@id}"
    return Team.map_items(sql)
  end

  def nations()
    sql = "SELECT nations.* FROM nations
    INNER JOIN athletes ON athletes.nation_id = nations.id
    INNER JOIN athlete_results ON athlete_results.athlete_id = athletes.id
    WHERE athlete_results.event_id = #{@id}"
    athlete_nations = Nation.map_items(sql)

    sql = "SELECT nations.* FROM nations
    INNER JOIN athletes ON athletes.nation_id = nations.id
    INNER JOIN team_members ON team_members.athlete_id = athlete_id
    INNER JOIN teams ON team_id = team_members.team_id
    INNER JOIN team_results ON team_results.team_id = teams.id
    WHERE team_results.event_id = #{@id} AND athletes.id = team_members.athlete_id"

    team_nations = Nation.map_items(sql)

    athlete_nations.concat(team_nations).uniq { |nation| nation.id }
  end

  def type()
    sql = "SELECT * FROM sports WHERE sports.id = #{sport_id}"
    sport = Sport.map_item(sql)
    return sport.type
  end

  def result()
    if @participation_type == "athlete"
      result = {}
      sql = "SELECT * FROM athlete_results WHERE athlete_results.event_id = #{@id}"
      result_hash = run(sql)
      result_hash.each do |event_result|
        sql = "SELECT * FROM athletes WHERE id = #{event_result['athlete_id']}"
        athlete = Athlete.map_item(sql)
        result["#{event_result['position']}"] = athlete
      end
    else
      result = {}
      sql = "SELECT * FROM team_results WHERE team_results.event_id = #{@id}"
      result_hash = run(sql)
      result_hash.each do |event_result|
        sql = "SELECT * FROM teams WHERE id = #{event_result['team_id']}"
        team = Team.map_item(sql)
        result["#{event_result['position']}"] = team
      end
    end
    return result
  end

  def self.all()
    sql = "SELECT * FROM events"
    return Event.map_items(sql)
  end

  def self.delete_all()
    sql = "DELETE FROM events"
    run(sql)
  end

  def self.map_items(sql)
    events = run(sql)
    result = events.map { |event| Event.new(event) }
    return result
  end

  def self.map_item(sql)
    result = map_items(sql)
    return result.first
  end

end