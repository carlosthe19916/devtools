Now I want you to design an endpoint that will get the details of a package regardless of the type.
- The endpoint needs to be a single one. E.g. "${API_URL}/api/pulp-content/${pulp_domain}/${pulp_domain_base_path}/simple/${package_name}"
- The endpoint should be defined in the pulpcore project and each pulp plugin should be able to overwrite the endpoint to customize the response
- The puplpcore should define a contract or the min data and then allow the plugings to enrich the response

The endpoint that I am asking you to define will be used by the UI /home/cferiavi/git/pulp/ui-packages.redhat.com
- Use /home/cferiavi/git/pulp/ui-packages.redhat.com/ui-api-mappings.md to understand what are the current needs of the UI in regards of what data is needed.

Understand the current endpoints that exist like:
- /api/pulp/{pulp_domain}/api/v3/content/file/files/
- /api/pulp/{pulp_domain}/api/v3/content/python/packages/
- /api/pulp/{pulp_domain}/api/v3/content/maven/package/
- /api/pulp/{pulp_domain}/api/v3/content/maven/artifact/
- /api/pulp/{pulp_domain}/api/v3/content/npm/packages/

Important: I want you to focus on the design of the endpoint (focus on the response body) not in the implementation
. Evaluate its feasability

Important info:
- pulp-service: /home/cferiavi/git/pulp/pulp-service
- pulpcore: /home/cferiavi/git/pulp/pulpcore
- pulp_python: /home/cferiavi/git/pulp/pulp_python
- pulp_maven: /home/cferiavi/git/pulp/pulp_maven

where pulp-service is like a wrapper of pulpcore+pulp_python+pulp_maven