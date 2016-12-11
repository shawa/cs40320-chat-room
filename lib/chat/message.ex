defmodule Message do
  def to_hash data do
    data |> String.split("\n")
         |> Enum.map(fn(x) -> split_strip(x) end)
         |> Enum.into(%{})
  end

  def from_list tuples do
    tuples |> Enum.map(fn({k, v}) -> "#{String.upcase(k)}: #{v}" end)
           |> Enum.join("\n")
  end

  defp split_strip line do
    [k, v] = String.split(line, ":")
    {k, String.lstrip(v)}
  end
end
