from pymongo import MongoClient
import os


def main():
    uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    db_name = os.getenv("DB_NAME", "HearYou")
    client = MongoClient(uri)
    db = client[db_name]
    coll = db["events"]

    # Remove fields from all existing documents
    res = coll.update_many({}, {"$unset": {"source": "", "description": ""}})
    print(f"Modified {res.modified_count} documents.")


if __name__ == "__main__":
    main()


