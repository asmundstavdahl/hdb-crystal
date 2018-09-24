require "http/server"
require "sqlite3"

DB.open "sqlite3://./data.db" do |db|
  create_tables_in db

  server = create_server db

  address = server.bind_tcp 8080
  puts "Listening on http://#{address}"
  server.listen
end

def create_tables_in(db)
  db.exec "create table if not exists `data` (`path` text, `value` text)"
end

def create_server(db)
  HTTP::Server.new do |context|
    context.response.content_type = "text/plain"

    case context.request.method
    when "GET"
      handle_GET context, db
    when "PUT"
      handle_PUT context, db
      #    when "POST"
      #      handle_PUT context, db
      #    when "DELETE"
      #      handle_PUT context, db
    else
      context.response.status_code = 405
      context.response.print "Method #{context.request.method} not allowed"
    end
  end
end

def value_at(db, path)
  db.scalar "select `value` from `data` where `path` = ?", path
end

def handle_GET(context, db)
  begin
    context.response.print (value_at db, context.request.path)
  rescue e : Exception
    if e.message == "no results"
      context.response.status_code = 404
    else
      context.response.status_code = 500
      context.response.print "error: #{e}"
    end
  end
end

def handle_PUT(context, db)
  begin
    body = context.request.body
    if body.is_a? Nil
      raise Exception.new "no request body"
    else
      db.exec "insert into `data` (`path`, `value`) values (?, ?)", context.request.path, body.gets_to_end
      context.response.status_code = 200
    end
  rescue e : Exception
    if e.message == "no results"
      context.response.status_code = 404
    else
      context.response.status_code = 500
      context.response.print "error: #{e}"
      raise e
    end
  end
end
