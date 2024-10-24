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


  type inputValue = {
    value: string,
    metric: string,
      state: string,
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
      top: {value: "", metric: "px", state: "default"},
      right: {value: "", metric: "px", state: "default"},
      bottom: {value: "", metric: "px", state: "default"},
      left: {value: "", metric: "px", state: "default"},
    }

    let (margins, setMargins) = React.useState(_ => initialDimensions)
    let (padding, setPadding) = React.useState(_ => initialDimensions)

    let createSideStyleObject = (inputValue) => {
    Js.Json.object_(
      Js.Dict.fromArray([
        ("value", Js.Json.string(inputValue.value)),
        ("metric", Js.Json.string(inputValue.metric)),
        ("state", Js.Json.string(inputValue.state))
        ]))
  }

    let createStylePayload = (elementId, isMargin, side, newValue, newMetric, newState) => {
  // Create the payload object using Js.Dict for a cleaner approach
  let payload = Js.Dict.empty()
  Js.Dict.set(payload, "elementId", Js.Json.string(elementId))
  let marginDict = Js.Dict.empty()
  let paddingDict = Js.Dict.empty()
  
  Js.Dict.set(marginDict, "top", createSideStyleObject(margins.top))
  Js.Dict.set(marginDict, "right", createSideStyleObject(margins.right))
  Js.Dict.set(marginDict, "bottom", createSideStyleObject(margins.bottom))
  Js.Dict.set(marginDict, "left", createSideStyleObject(margins.left))

  Js.Dict.set(paddingDict, "top", createSideStyleObject(padding.top))
  Js.Dict.set(paddingDict, "right", createSideStyleObject(padding.right))
  Js.Dict.set(paddingDict, "bottom", createSideStyleObject(padding.bottom))
  Js.Dict.set(paddingDict, "left", createSideStyleObject(padding.left))

// Realtime Update
  Js.Dict.set(isMargin ? marginDict : paddingDict, side, createSideStyleObject({value: newValue, metric: newMetric, state: newState}))

  Js.Dict.set(payload, "margin", Js.Json.object_(marginDict))
  Js.Dict.set(payload, "padding", Js.Json.object_(paddingDict))
  payload
  }

    let updateDimension = (isMargin, side, newValue, newMetric, newState) => {
      let setter = isMargin ? setMargins : setPadding
      setter(prevDimensions => {
        switch side {
        | "top" => {...prevDimensions, top: {value: newValue, metric: newMetric, state: newState}}
        | "right" => {...prevDimensions, right: {value: newValue, metric: newMetric, state: newState}}
        | "bottom" => {...prevDimensions, bottom: {value: newValue, metric: newMetric, state: newState}}
        | "left" => {...prevDimensions, left: {value: newValue, metric: newMetric, state: newState}}
        | _ => prevDimensions
        }
      })

      let payload = createStylePayload("exampleElementId", isMargin, side, newValue, newMetric, newState)
      let headers = Js.Dict.empty()
      Js.Dict.set(headers, "Content-Type", "application/json")

      Fetch.fetchJsonPost(`http://localhost:12346/styles/update`, ~body=Some(Js.Json.stringify(Js.Json.object_(payload))), ~headers=headers)
      |> ignore
    }

     React.useEffect1(() => {
      Fetch.fetchJson(`http://localhost:12346/styles/margin/exampleElementId`)
      |> Js.Promise.then_(marginJson => {
        Js.Promise.resolve(setMargins(_ =>(Obj.magic(marginJson))))
      })
      |> Js.Promise.catch(_ => {
        Js.Promise.resolve()
      })
      |> ignore
      None
    }, [setMargins])

         React.useEffect1(() => {
      Fetch.fetchJson(`http://localhost:12346/styles/padding/exampleElementId`)
      |> Js.Promise.then_(paddingJson => {
        Js.Promise.resolve(setPadding(_ =>(Obj.magic(paddingJson))))
      })
      |> Js.Promise.catch(_ => {
        Js.Promise.resolve()
      })
      |> ignore
      None
    }, [setPadding])


    let renderInput = (setter, side, {value, metric, state}) => {
      let inputClassName = switch state {
      | "changed" => "input-changed"
      | "focused" => "input-focused"
      | _ => "input-default"
      }

      <div className="input-group">
        <input
          type_="number"
          value
          className={`dimension-input ${inputClassName}`}
          placeholder="auto"
          onFocus={_ => updateDimension(setter, side, value, metric, "focused")}
          onBlur={_ => updateDimension(setter, side, value, metric, if value !== "" { "changed" } else { "default" })}
          onChange={e => {
            let newValue = ReactEvent.Form.target(e)["value"]
            updateDimension(setter, side, newValue, metric, "focused")
          }}
        />
        <select
          className="metric-select"
          value={metric}
          onChange={e => {
            let newMetric = ReactEvent.Form.target(e)["value"] === "px" ? "px" : "%"
            updateDimension(setter, side, value, newMetric, if value !== "" { "changed" } else { "default" })
          }}>
          <option value="px"> {React.string("px")} </option>
          <option value="%"> {React.string("%")} </option>
        </select>
      </div>
    }

    <div className="margin-padding-container">
      <div className="margin-padding-inner">
        <div className="margin-top">{renderInput(true, "top", margins.top)}</div>
        <div className="margin-horizontal">
          <div className="margin-left">{renderInput(true, "left", margins.left)}</div>
          <div className="content-area">
            <div className="padding-top">{renderInput(false, "top", padding.top)}</div>
            <div className="padding-horizontal">
              <div className="padding-left">{renderInput(false, "left", padding.left)}</div>
              <div className="inner-content">{"Content"->React.string}</div>
              <div className="padding-right">{renderInput(false, "right", padding.right)}</div>
            </div>
            <div className="padding-bottom">{renderInput(false, "bottom", padding.bottom)}</div>
          </div>
          <div className="margin-right">{renderInput(true, "right", margins.right)}</div>
        </div>
        <div className="margin-bottom">{renderInput(true, "bottom", margins.bottom)}</div>
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
