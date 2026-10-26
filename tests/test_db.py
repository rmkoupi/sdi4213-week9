import os
from sqlalchemy import create_engine
from app.db import initialize_database, create_request, list_requests, update_status


def test_create_and_list_request():
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    initialize_database(engine)
    create_request(engine, "Projector not working", "Hardware", "High", "Room 204 projector has no image")
    rows = list_requests(engine)
    assert len(rows) == 1
    assert rows[0]["title"] == "Projector not working"
    assert rows[0]["status"] == "Open"


def test_update_status():
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    initialize_database(engine)
    create_request(engine, "Install software", "Software", "Medium", "Install approved package")
    row = list_requests(engine)[0]
    update_status(engine, row["id"], "Closed")
    assert list_requests(engine)[0]["status"] == "Closed"
