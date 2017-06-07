defmodule Credo.Check.Consistency.ParameterPatternMatching.Collector do
  use Credo.Check.Consistency.Collector

  alias Credo.Code

  def collect_values(source_file, _params) do
    position_recorder = &record_position/4

    Code.prewalk(source_file, &traverse(position_recorder, &1, &2), %{})
  end

  def find_locations(kind, source_file) do
    location_recorder = &record_location(kind, &1, &2, &3, &4)

    source_file
    |> Code.prewalk(&traverse(location_recorder, &1, &2), [])
    |> Enum.reverse
  end

  defp traverse(callback, {:def, _, [{_name, _, params}, _]} = ast, acc) when is_list(params) do
    {ast, traverse_params(callback, params, acc)}
  end
  defp traverse(callback, {:defp, _, [{_name, _, params}, _]} = ast, acc) when is_list(params) do
    {ast, traverse_params(callback, params, acc)}
  end
  defp traverse(_callback, ast, acc), do: {ast, acc}

  defp traverse_params(callback, params, acc) do
    Enum.reduce(params, acc, fn
      ({:=, _, [{capture_name, meta, nil}, _rhs]}, param_acc) ->
        callback.(:before, capture_name, meta, param_acc)
      ({:=, _, [_lhs, {capture_name, meta, nil}]}, param_acc) ->
        callback.(:after, capture_name, meta, param_acc)
      (_, param_acc) ->
        param_acc
    end)
  end

  defp record_position(kind, _capture_name, _meta, acc) do
    Map.update(acc, kind, 1, &(&1 + 1))
  end

  defp record_location(expected_kind, kind, capture_name, meta, acc) do
    if kind == expected_kind,
      do: [[line_no: meta[:line], trigger: capture_name] | acc], else: acc
  end
end
