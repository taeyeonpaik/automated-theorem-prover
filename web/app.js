// All interface markup is constructed here. Native controls; no CSS, packages,
// external fonts, framework, or build step. textContent keeps formulas inert.
const el = (tag, text = "", props = {}) => Object.assign(document.createElement(tag), {textContent: text}, props);
const add = (parent, ...children) => { parent.append(...children); return parent; };
const paragraph = text => el("p", text);
const table = (headers, rows) => {
  const t = el("table");
  add(t, add(el("thead"), add(el("tr"), ...headers.map(h => el("th", h)))));
  add(t, add(el("tbody"), ...rows.map(row => add(el("tr"), ...row.map(x => el("td", String(x)))))));
  return t;
};
const api = async (url, body) => {
  const response = await fetch(url, body ? {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify(body)} : {});
  const result = await response.json();
  if (!response.ok) throw Error(result.error || "Request failed");
  return result;
};

const main = el("main");
document.body.append(main);
add(main, el("h1", "QED"), paragraph("QED v2 · A small first-order theorem prover. Enter what you know and what you want to prove."));
const examples = el("select", "", {id: "examples", ariaLabel: "Example problem"});
const load = el("button", "Load example", {type: "button"});
const description = paragraph("");
add(main, add(el("section"), el("h2", "Try a problem"), examples, document.createTextNode(" "), load, description));

const form = el("form");
const premises = el("textarea", "", {id: "premises", rows: 7, cols: 76, spellcheck: false});
const goal = el("input", "", {id: "goal", size: 76, required: true, spellcheck: false});
const mode = el("select", "", {id: "mode"});
add(mode, el("option", "Optimized", {value: "optimized"}), el("option", "Baseline (FIFO)", {value: "baseline"}));
const seconds = el("input", "", {id: "seconds", type: "number", min: "0.01", max: "30", step: "0.01", value: "3", required: true});
const cap = el("input", "", {id: "cap", type: "number", min: "1", max: "50000", value: "5000", required: true});
const field = (name, control) => add(el("p"), el("label", name, {htmlFor: control.id}), el("br"), control);
const prove = el("button", "Prove", {type: "submit"});
const compare = el("button", "Compare both modes", {type: "button"});
add(form, field("Premises — one formula per line", premises), field("Conclusion", goal),
  field("Search mode", mode), field("Time limit per run (seconds)", seconds), field("Clause limit", cap),
  prove, document.createTextNode(" "), compare);
main.append(form);
const help = add(el("details"), el("summary", "Syntax and examples"),
  el("pre", "forall x. human(x) -> mortal(x)\nexists x. human(x)\n(p & q) -> r\np | ~p\na = b\nf(a) != b\np <-> q"),
  paragraph("Use ~ for not, & for and, | for or, -> for implies, and <-> for if and only if. Quantifiers extend to the end of their enclosing parentheses. Lowercase term names are constants unless bound by a quantifier; free uppercase term names are universally quantified. Function names are lowercase."),
  paragraph("This is formal logic, not natural-language input or a calculator. Equality is supported; arithmetic is not built in. No premises means you are asking whether the conclusion is logically valid."));
main.append(help);
const output = el("section", "", {ariaLive: "polite"});
const historySection = el("section");
const evaluationSection = el("section");
const fullEvaluationSection = el("section");
add(main, el("hr"), output, el("hr"), fullEvaluationSection, el("hr"), evaluationSection, el("hr"), historySection);

const busy = state => { prove.disabled = compare.disabled = load.disabled = state; };
const problem = () => ({premises: premises.value, goal: goal.value, mode: mode.value,
  seconds: Number(seconds.value), max_clauses: Number(cap.value)});
const download = result => {
  const blob = new Blob([JSON.stringify(result, null, 2)], {type: "application/json"});
  const url = URL.createObjectURL(blob);
  const a = el("a", "", {href: url, download: "qed-proof.json"}); a.click(); URL.revokeObjectURL(url);
};
const render = result => {
  const title = {proved: "Proved", not_entailed: "Does not follow", unknown: "Unknown — search limit reached", error: "Check your input"}[result.status];
  const section = add(el("section"), el("h2", `${title} · ${result.mode}`), paragraph(result.reason));
  if (result.status === "not_entailed") section.append(paragraph("QED exhausted the complete clause search. This conclusion is not entailed by these premises; it does not mean the conclusion is always false. No countermodel is constructed."));
  if (result.status === "proved") section.append(paragraph("Recorded inference steps checked (including equality in v2). Parsing, normalization, and baseline equality axioms are trusted. A proof establishes a consequence of your premises; it does not establish that the premises are consistent."));
  const m = result.metrics;
  section.append(table(["Measure", "Value"], [
    ["Prover time", m.elapsed_ms === undefined ? "Unavailable" : `${m.elapsed_ms.toFixed(3)} ms`],
    ["Peak prover process memory", `${(m.peak_rss_bytes / 1048576).toFixed(2)} MiB`],
    ["Clauses selected", m.selected_clauses ?? "—"], ["Literal pairs checked", m.literal_pair_checks ?? "—"],
    ["Redundant clauses removed", m.redundant_clauses ?? "—"], ["Proof steps", m.proof_steps ?? "—"]]));
  const proof = add(el("details"), el("summary", `Proof trace (${result.proof.length} steps)`));
  if (!result.proof.length) proof.append(paragraph("No proof was produced."));
  for (const step of result.proof) {
    const detail = add(el("details"), el("summary", `${step.id}. ${step.clause}`),
      paragraph(`${step.rule}${step.source ? ": " + step.source : " from " + step.parents.join(", ")}`),
      el("pre", JSON.stringify({pivots: step.pivots, direction: step.direction, term_position: step.term_position, substitution: step.substitution}, null, 2)));
    proof.append(detail);
  }
  section.append(proof);
  section.append(add(el("details"), el("summary", "All measurements"), el("pre", JSON.stringify(m, null, 2))));
  const save = el("button", "Download run & proof", {type: "button"}); save.onclick = () => download(result);
  section.append(save); output.append(section);
};
const refreshHistory = async () => {
  const history = await api("/api/history");
  historySection.replaceChildren(el("h2", "Saved runs"));
  const c = history.counts;
  historySection.append(paragraph(`${c.problems} distinct problems · ${c.runs} runs · ${c.distinct_proved_problems} distinct proved problems · ${c.checked_proof_runs} checked proof runs · ${c.distinct_premise_texts} distinct premise texts`));
  historySection.append(paragraph("Saved premises belong to their own problems. They are never silently added to a new proof."));
  const list = el("ul");
  for (const run of history.runs.slice(0, 15)) {
    const button = el("button", `#${run.id} · ${run.status} · ${run.goal}`, {type: "button"});
    button.onclick = () => { output.replaceChildren(); render(run.result); };
    list.append(add(el("li"), button));
  }
  historySection.append(list);
};
const execute = async both => {
  if (!form.reportValidity()) return;
  busy(true); output.replaceChildren(paragraph("Searching for a proof…"));
  try {
    const input = problem(); const results = [];
    for (const chosen of both ? ["baseline", "optimized"] : [input.mode]) {
      results.push(await api("/api/prove", {...input, mode: chosen}));
    }
    output.replaceChildren();
    if (both) {
      output.append(el("h2", "Comparison"), paragraph("Same problem and limits. Very short timings are noisy; use the benchmark runner for repeated measurements."));
      output.append(table(["Mode", "Result", "Time (ms)", "Pairs checked", "Clauses kept"],
        results.map(r => [r.mode, r.status, r.metrics.elapsed_ms ?? "—", r.metrics.literal_pair_checks ?? "—", r.metrics.kept_clauses ?? "—"])));
    }
    results.forEach(render); await refreshHistory();
  } catch (error) { output.replaceChildren(paragraph(error.message)); }
  finally { busy(false); }
};
form.onsubmit = event => { event.preventDefault(); execute(false); };
compare.onclick = () => execute(true);
const refreshEvaluation = async () => {
  const report = await api("/api/evaluation");
  evaluationSection.replaceChildren(el("h2", "Historical TPTP regression suite (64 problems)"));
  if (report.available === false) {
    evaluationSection.append(paragraph("Run python3 fetch_tptp.py, then python3 benchmark.py --tptp --seconds 2 --repeat 3 to create the evaluation."));
    return;
  }
  evaluationSection.append(paragraph(`${report.corpus}. ${report.complete ? "Completed" : "In progress"}: ${report.repeat} repetitions, ${report.limits.seconds} seconds and ${report.limits.max_clauses} clauses per run.`));
  evaluationSection.append(paragraph("This fixed historical subset includes unsolved and unsupported problems. A problem counts as solved only when every repetition agrees with its published status. Inference checking trusts preprocessing."));
  evaluationSection.append(table(["Mode", "Solved / selected", "Checked proofs / positive cases", "Unsupported", "Mismatches"],
    Object.entries(report.summary).map(([mode, s]) => [mode, `${s.correct_all_repetitions}/${s.total_selected}`,
      `${s.checked_proved_problems}/${s.positive_problems}`, s.unsupported, s.answer_mismatches])));
  const select = el("select", "", {ariaLabel: "TPTP problem"});
  report.problems.forEach(p => select.append(el("option", `${p.name.split('/').pop()} · ${p.expected_tptp_status}${p.unsupported ? " · unsupported" : ""}`, {value: p.name})));
  const button = el("button", "Load TPTP problem", {type: "button"});
  button.onclick = async () => {
    try {
      const p = await api(`/api/tptp/problem?name=${encodeURIComponent(select.value)}`);
      premises.value = p.premises.join("\n"); goal.value = p.goal;
      seconds.value = String(report.limits.seconds); cap.value = String(report.limits.max_clauses);
      description.textContent = `${p.name} · TPTP 3.3.0 · published status: ${p.expected_tptp_status}. Edit or run it above. Axiom-file includes have been expanded.`;
      output.replaceChildren();
    } catch (error) { output.replaceChildren(paragraph(error.message)); }
  };
  const refresh = el("button", "Refresh evaluation", {type: "button"});
  refresh.onclick = () => refreshEvaluation().catch(error => output.replaceChildren(paragraph(error.message)));
  add(evaluationSection, paragraph("Inspect an individual benchmark problem:"), select, document.createTextNode(" "), button,
    document.createTextNode(" "), refresh, paragraph("Re-run the 64-problem regression suite: python3 benchmark.py --tptp --seconds 2 --repeat 3"),
    el("a", "Download historical evaluation JSON", {href: "/api/evaluation/report", download: "qed-tptp-results.json"}));
};
const refreshFullEvaluation = async () => {
  const report = await api("/api/full-evaluation");
  fullEvaluationSection.replaceChildren(el("h2", "Full TPTP 9.3.1 evaluation · QED v2"));
  if (report.available === false) {
    fullEvaluationSection.append(paragraph(report.pipeline ? "Preparing the QED v2 evaluation. Refresh this page shortly." : "No QED v2 evaluation has been started."));
    return;
  }
  fullEvaluationSection.append(paragraph("This is a fresh evaluation of QED v2 with the same corpus and limits as v1. The original results are preserved."));
  const stage = {coverage: "Input checks and full search", timing: "Sequential timing measurements", complete: "Complete — search, timings and artifact checks finished", failed: "Stopped — needs attention"}[report.pipeline?.stage];
  if (stage) fullEvaluationSection.append(paragraph(`Evaluation stage: ${stage}${report.pipeline.error ? ". " + report.pipeline.error : ""}`));
  add(fullEvaluationSection, el("a", "Download preserved v1 results", {href: "/api/full-evaluation/v1", download: "qed-v1-results.json"}), document.createTextNode(" · "),
    el("a", "Download preserved v1 timings", {href: "/api/full-evaluation/v1-metrics", download: "qed-v1-timings.json"}));
  fullEvaluationSection.append(paragraph(`${report.complete ? "Full search completed" : "In progress — partial results"}. ${report.selected_problems.toLocaleString()} FOF/CNF problems selected. Preflight: ${report.preflight_completed.toLocaleString()}. Measured runs: ${report.completed_runs.toLocaleString()}.`));
  fullEvaluationSection.append(paragraph(`${report.seconds} seconds and ${report.max_clauses} clauses per run, one run per mode. ${report.workers} concurrent workers; use the sequential suite for timing comparisons. Unsupported inputs remain in the selected total. Known bug-list entries and unknown reference answers are unscored.`));
  fullEvaluationSection.append(table(["Mode", "Correct proofs", "Correct negative decisions", "Unknown", "Errors", "Mismatches"],
    Object.entries(report.summary).map(([m, s]) => [m, s.correct_proofs, s.correct_negative_decisions, s.statuses.unknown ?? 0, s.statuses.error ?? 0, s.mismatches])));
  fullEvaluationSection.append(paragraph(`Input checks: ${Object.entries(report.preflight_states).map(([state, count]) => `${count} ${state}`).join(" · ")}`));
  const metrics = await api("/api/full-evaluation/metrics");
  if (metrics.available === false || !metrics.complete) {
    fullEvaluationSection.append(paragraph("Paired runtime and literal-comparison medians will appear after the full search and sequential timing reruns finish."));
  } else {
    fullEvaluationSection.append(paragraph(`Paired efficiency: ${metrics.aggregate.problems} shared, verified successes; three sequential runs per mode. These medians describe this shared-success subset. Literal comparisons count resolution-generator work, excluding simplification and paramodulation.`));
    fullEvaluationSection.append(table(["Metric", "Baseline median", "Optimized median", "Reduction"],
      Object.entries(metrics.aggregate.fields).map(([name, s]) => [name === "median_ms" ? "Prover time (ms)" : "Candidate literal comparisons",
        s.median.baseline?.toFixed(4) ?? "—", s.median.optimized?.toFixed(4) ?? "—", s.median.reduction_percent === null ? "—" : `${s.median.reduction_percent.toFixed(2)}%`])));
    fullEvaluationSection.append(el("a", "Download paired metrics", {href: "/api/full-evaluation/metrics", download: "qed-tptp-paired-metrics.json"}));
  }
  const refresh = el("button", "Refresh full evaluation", {type: "button"});
  refresh.onclick = () => refreshFullEvaluation().catch(error => output.replaceChildren(paragraph(error.message)));
  const name = el("input", "", {ariaLabel: "TPTP 9.3.1 problem identifier", placeholder: "SYN001+1", value: "SYN001+1"});
  const button = el("button", "Load 9.3.1 problem", {type: "button"});
  button.onclick = async () => {
    try {
      const p = await api(`/api/full-tptp/problem?name=${encodeURIComponent(name.value.trim())}`);
      premises.value = p.premises.join("\n"); goal.value = p.goal;
      seconds.value = String(report.seconds); cap.value = String(report.max_clauses);
      description.textContent = `${p.name} · TPTP 9.3.1 · published status: ${p.expected_tptp_status}. Referenced axiom sets are included in the premises.`;
      output.replaceChildren();
    } catch (error) { output.replaceChildren(paragraph(error.message)); }
  };
  add(fullEvaluationSection, refresh, paragraph("Inspect a problem by its TPTP identifier:"), name, document.createTextNode(" "), button);
  if (report.complete) fullEvaluationSection.append(paragraph(""), el("a", "Download all per-problem results (CSV)", {href: "/api/full-evaluation/results.csv", download: "qed-tptp-9.3.1.csv"}));
};
try {
  const data = await api("/api/examples");
  data.forEach((example, i) => examples.append(el("option", example.name, {value: String(i)})));
  load.onclick = () => {
    const example = data[Number(examples.value)];
    premises.value = example.premises.join("\n"); goal.value = example.goal; description.textContent = example.description;
    output.replaceChildren();
  };
  load.click(); await refreshHistory(); await refreshFullEvaluation(); await refreshEvaluation();
} catch (error) { output.replaceChildren(paragraph(error.message)); }
