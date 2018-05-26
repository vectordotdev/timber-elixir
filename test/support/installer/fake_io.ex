defmodule Timber.Installer.FakeIO do
  use Timber.Stubbing

  def binwrite(file, contents) do
    get_stub!(:binwrite).(file, contents)
  end

  def gets(message) do
    write_output(message)
    v = get_stub!(:gets).(message)
    write_output(v)
    v
  end

  def puts(message) do
    write_output("#{message}\n")
  end

  def write(message) do
    write_output(message)
  end

  def write_output(message) do
    Agent.update(__MODULE__, fn state ->
      existing = Map.get(state, :output, "")
      Map.put(state, :output, "#{existing}#{message}")
    end)
  end

  def get_output do
    Agent.get(__MODULE__, &Map.get(&1, :output, []))
  end
end
