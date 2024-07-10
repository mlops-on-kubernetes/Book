import json
from sklearn.feature_extraction.text import CountVectorizer

def json_to_feature_vector(json_data):
    # Convert JSON to string
    json_str = json.dumps(json_data)

    # Initialize CountVectorizer
    vectorizer = CountVectorizer()

    # Fit and transform the data
    feature_vector = vectorizer.fit_transform([json_str])

    return feature_vector.toarray()

# Example JSON data
example_json = {
"num_rooms": 6,
"num_bedrooms": 3,
"street_name": "Shorebird Way",
"num_basement_rooms": -1,
}

# Convert JSON to feature vector
feature_vector = json_to_feature_vector(example_json)

print("Feature vector:")
print(feature_vector)
