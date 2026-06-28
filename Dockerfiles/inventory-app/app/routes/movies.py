from flask import Blueprint, request
from ..models import Movie, db

movies_bp = Blueprint("movies_bp", __name__, url_prefix="/api/movies")


@movies_bp.route("/", methods=["GET"])
def list_movies():
    """List all movies"""

    search_query = request.args.get("title")
    if search_query:
        movies = Movie.query.filter(Movie.title.ilike(f"%{search_query}%"))
    else:
        movies = Movie.query.all()
    return [movie.to_dict() for movie in movies]


@movies_bp.route("/", methods=["POST"])
def create_movie():
    """Create a movie"""
    
    data = request.get_json()
    if not data or "title" not in data or not data["title"].strip():
        return {"error": "Missing or invalid title"}, 400

    movie = Movie(title=data["title"], description=data.get("description", ""))
    db.session.add(movie)
    db.session.commit()
    return movie.to_dict(), 201

@movies_bp.route('/', methods=["DELETE"])
def delete_movies():
    """Delete All movies"""
    Movie.query.delete()
    db.session.commit()
    return '', 204

@movies_bp.route("/<int:id>", methods=["GET", "PUT", "DELETE"])
def get_movie(id):
    movie = Movie.query.get(id)
    if not movie:
        return {"error": "Movie not found"}, 404
    match request.method:
        case "PUT":
            data = request.get_json()
            if not data or "title" not in data or not data["title"].strip():
                return {"error": "Missing or invalid title"}, 400
            movie.title = data["title"]
            movie.description = data.get("description", movie.description)
            db.session.commit()
        case "DELETE":
            db.session.delete(movie)
            db.session.commit()
            return '', 204
    return movie.to_dict()

