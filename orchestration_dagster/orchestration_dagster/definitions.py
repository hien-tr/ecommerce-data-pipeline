from dagster import Definitions
from dagster_dbt import DbtCliResource
from .assets import ecommerce_dbt_assets
from .project import ecommerce_project
from .schedules import schedules

defs = Definitions(
    assets=[ecommerce_dbt_assets],
    schedules=schedules,
    resources={
        "dbt": DbtCliResource(project_dir=ecommerce_project),
    },
)