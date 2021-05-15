open Belt
open ReScriptUrql

module GetAllJobs = %graphql(`
{ jobs { owner, name, hash, variant, outcome, error } }
`)
external outcome_to_string: GetAllJobs.t_jobs_outcome => string = "%identity"

module JobRow = {
  @react.component
  let make = (~job: GetAllJobs.t_jobs) => {
    let onClick = ev => {
      ev->ReactEvent.Synthetic.stopPropagation
      ev->ReactEvent.Synthetic.preventDefault
      let href = `http://localhost:8090/github/${job.owner}/${job.name}/commit/${job.hash}/variant/${job.variant}`
      Window_utils.windowOpen(href)
    }

    if job.variant == "(analysis)" {
      React.null
    } else {
      <tr onClick={onClick}>
        <td> {`${job.owner}/${job.name}`->React.string} </td>
        <td> {Js.String2.substring(job.hash, ~from=0, ~to_=8)->React.string} </td>
        <td> {job.variant->React.string} </td>
        <td> <OutcomeDisplay outcome={outcome_to_string(job.outcome)} err={job.error} /> </td>
      </tr>
    }
  }
}

module Content = {
  @react.component
  let make = (~jobs: array<GetAllJobs.t_jobs>) => {
    <table className="table">
      <thead>
        <tr>
          <th> {"Repo"->React.string} </th>
          <th> {"Hash"->React.string} </th>
          <th> {"Variant"->React.string} </th>
          <th> {"Outcome"->React.string} </th>
        </tr>
      </thead>
      <tbody>
        {Array.mapWithIndex(jobs, (idx, job) =>
          <JobRow key={idx->Int.toString} job={job} />
        )->React.array}
      </tbody>
    </table>
  }
}

@react.component
let make = () => {
  let ({Hooks.response: response}, _) = Hooks.useQuery(
    ~query=module(GetAllJobs),
    ~requestPolicy=#CacheFirst,
    (),
  )

  <main>
    <div className="p-8">
      {switch response {
      | Fetching => "Loading"->React.string
      | Error(e) => e.message->React.string
      | Empty => "Not Found"->React.string
      | Data(data)
      | PartialData(data, _) =>
        <Content jobs={data.jobs} />
      }}
    </div>
  </main>
}
