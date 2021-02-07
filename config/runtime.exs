import Config

if config_env() != :test do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :hello, HelloWeb.Endpoint,
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]],
      protocol_options: [max_keepalive: 5_000_000]
    ],
    secret_key_base: secret_key_base
end

if System.get_env("RELEASE_MODE") do
  config :hello, HelloWeb.Endpoint, server: true
end
