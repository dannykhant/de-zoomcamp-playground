import dlt
from dlt.sources.rest_api import rest_api_resources
from dlt.sources.rest_api.typing import RESTAPIConfig


@dlt.source
def taxi_rest_api_source():
    """Source that pages through the NYC taxi API.

    The API returns plain JSON lists of 1,000 records per page.  A new
    page is requested by supplying `?page=<n>` and pagination ends when an
    empty list is returned.
    """
    config: RESTAPIConfig = {
        "client": {
            "base_url": "https://us-central1-dlthub-analytics.cloudfunctions.net/data_engineering_zoomcamp_api",
        },
        "resources": [
            {
                "name": "taxi",
                "endpoint": {
                    # root path returns the list directly
                    "path": "",
                    # use page-number pagination, stop when a page comes back
                    # empty (default behaviour)
                    "paginator": {
                        "type": "page_number",
                        "page_param": "page",
                        "base_page": 1,
                        "total_path": None,  # API returns bare array, no total field
                    },
                    # the body is a bare array so no special selector is needed
                },
            }
        ],
    }

    yield from rest_api_resources(config)


pipeline = dlt.pipeline(
    pipeline_name="taxi_pipeline",
    destination="duckdb",
    refresh="drop_sources",  # clean state while we develop
    progress="log",
)


if __name__ == "__main__":
    info = pipeline.run(taxi_rest_api_source())
    print(info)
