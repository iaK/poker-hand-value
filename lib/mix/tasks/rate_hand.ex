defmodule Mix.Tasks.RateHand do
  use Mix.Task

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, aliases: [h: :hand], strict: [hand: :string])

    best_hand = PokerHandValue.rate_hand(opts[:hand])
    IO.puts(Atom.to_string(elem(best_hand, 0)) <> ", " <> Float.to_string(elem(best_hand, 1)))
  end
end
