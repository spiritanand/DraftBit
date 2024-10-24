%raw(`require("./PropertiesPanel.css")`)
%raw(`require("./MarginPadding.css")`)

module Collapsible = {
  @react.component
  let make = (~title, ~children) => {
    let (collapsed, toggle) = React.useState(() => false)

    <section className="Collapsible">
      <button className="Collapsible-button" onClick={_e => toggle(_ => !collapsed)}>
        <span> {React.string(title)} </span> <span> {React.string(collapsed ? "+" : "-")} </span>
      </button>
      {collapsed ? React.null : <div className="Collapsible-content"> {children} </div>}
    </section>
  }
}

// This component provides a simplified example of fetching JSON data from
// the backend and rendering it on the screen.
module ViewExamples = {
  // Type of the data returned by the /examples endpoint
  type example = {
    id: int,
    some_int: int,
    some_text: string,
  }

  @react.component
  let make = () => {
    let (examples: option<array<example>>, setExamples) = React.useState(_ => None)

    React.useEffect1(() => {
      // Fetch the data from /examples and set the state when the promise resolves
      Fetch.fetchJson(`http://localhost:12346/examples`)
      |> Js.Promise.then_(examplesJson => {
        // NOTE: this uses an unsafe type cast, as safely parsing JSON in rescript is somewhat advanced.
        Js.Promise.resolve(setExamples(_ => Some(Obj.magic(examplesJson))))
      })
      // The "ignore" function is necessary because each statement is expected to return `unit` type, but Js.Promise.then return a Promise type.
      |> ignore
      None
    }, [setExamples])

    <div>
      {switch examples {
      | None => React.string("Loading examples....")
      | Some(examples) =>
        examples
        ->Js.Array2.map(example =>
          React.string(`Int: ${example.some_int->Js.Int.toString}, Str: ${example.some_text}`)
        )
        ->React.array
      }}
    </div>
  }
}

module MarginPadding = {
  type metric = Px | Percent
  type inputState = Default | Changed | Focused

  type inputValue = {
    value: string,
    metric: metric,
    state: inputState,
  }

  type dimensions = {
    top: inputValue,
    right: inputValue,
    bottom: inputValue,
    left: inputValue,
  }

  @react.component
  let make = () => {
    let initialDimensions = {
      top: {value: "", metric: Px, state: Default},
      right: {value: "", metric: Px, state: Default},
      bottom: {value: "", metric: Px, state: Default},
      left: {value: "", metric: Px, state: Default},
    }

    let (margins, setMargins) = React.useState(_ => initialDimensions)
    let (padding, setPadding) = React.useState(_ => initialDimensions)

    let updateDimension = (setter, side, newValue, newMetric, newState) => {
      setter(prevDimensions => {
        switch side {
        | "top" => {...prevDimensions, top: {value: newValue, metric: newMetric, state: newState}}
        | "right" => {...prevDimensions, right: {value: newValue, metric: newMetric, state: newState}}
        | "bottom" => {...prevDimensions, bottom: {value: newValue, metric: newMetric, state: newState}}
        | "left" => {...prevDimensions, left: {value: newValue, metric: newMetric, state: newState}}
        | _ => prevDimensions
        }
      })
    }

    let renderInput = (setter, side, {value, metric, state}) => {
      let inputClassName = switch state {
      | Default => "input-default"
      | Changed => "input-changed"
      | Focused => "input-focused"
      }

      <div className="input-group">
        <input
          type_="number"
          value
          className={`dimension-input ${inputClassName}`}
          placeholder="auto"
          onFocus={_ => updateDimension(setter, side, value, metric, Focused)}
          onBlur={_ => updateDimension(setter, side, value, metric, if value !== "" {Changed} else {Default})}
          onChange={e => {
            let newValue = ReactEvent.Form.target(e)["value"]
            updateDimension(setter, side, newValue, metric, Focused)
          }}
        />
        <select
          className="metric-select"
          value={metric == Px ? "px" : "%"}
          onChange={e => {
            let newMetric = ReactEvent.Form.target(e)["value"] == "px" ? Px : Percent
            updateDimension(setter, side, value, newMetric, if value !== "" {Changed} else {Default})
          }}>
          <option value="px"> {React.string("px")} </option>
          <option value="%"> {React.string("%")} </option>
        </select>
      </div>
    }

    <div className="margin-padding-container">
      <div className="margin-padding-inner">
        <div className="margin-top">{renderInput(setMargins, "top", margins.top)}</div>
        <div className="margin-horizontal">
          <div className="margin-left">{renderInput(setMargins, "left", margins.left)}</div>
          <div className="content-area">
            <div className="padding-top">{renderInput(setPadding, "top", padding.top)}</div>
            <div className="padding-horizontal">
              <div className="padding-left">{renderInput(setPadding, "left", padding.left)}</div>
              <div className="inner-content">{"Content"->React.string}</div>
              <div className="padding-right">{renderInput(setPadding, "right", padding.right)}</div>
            </div>
            <div className="padding-bottom">{renderInput(setPadding, "bottom", padding.bottom)}</div>
          </div>
          <div className="margin-right">{renderInput(setMargins, "right", margins.right)}</div>
        </div>
        <div className="margin-bottom">{renderInput(setMargins, "bottom", margins.bottom)}</div>
      </div>
    </div>
  }
}

@genType @genType.as("PropertiesPanel") @react.component
let make = () =>
  <aside className="PropertiesPanel">
    <Collapsible title="Load examples"> <ViewExamples /> </Collapsible>
    <Collapsible title="Margins & Padding">
      <MarginPadding />
    </Collapsible>
    <Collapsible title="Size"> <span> {React.string("example")} </span> </Collapsible>
  </aside>
