defmodule PokerHandValue.MixProject do
  use Mix.Project

  def project do
    [
      app: :poker_hand_value,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      name: "PokerHandValue",
      source_url: "https://github.com/iaK/poker-hand-value"
    ]
  end

  defp description() do
    "A library to rate poker hands"
  end

  defp package() do
    [
      # These are the default files included in the package
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/iaK/poker-hand-value"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end
end
