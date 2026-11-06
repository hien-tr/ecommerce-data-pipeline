from dagster import AssetExecutionContext
from dagster_dbt import DbtCliResource, dbt_assets

from .project import ecommerce_project


@dbt_assets(manifest=ecommerce_project.manifest_path)
def ecommerce_dbt_assets(context: AssetExecutionContext, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()
    