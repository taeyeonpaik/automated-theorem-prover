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
add(main, el("h1", "QED"), paragraph("A small first-order theorem prover. Enter what you know and what you want to prove."));
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
add(main, el("hr"), output, el("hr"), historySection);

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
  if (result.status === "proved") section.append(paragraph("Resolution/factoring steps checked. Parsing, normalization, and generated equality axioms are trusted. A proof establishes a consequence of your premises; it does not establish that the premises are consistent."));
  const m = result.metrics;
  section.append(table(["Measure", "Value"], [
    ["Prover time", m.elapsed_ms === undefined ? "Unavailable (hard limit)" : `${m.elapsed_ms.toFixed(3)} ms`],
    ["Peak prover process memory", `${(m.peak_rss_bytes / 1048576).toFixed(2)} MiB`],
    ["Clauses selected", m.selected_clauses ?? "—"], ["Literal pairs checked", m.literal_pair_checks ?? "—"],
    ["Redundant clauses removed", m.redundant_clauses ?? "—"], ["Proof steps", m.proof_steps ?? "—"]]));
  const proof = add(el("details"), el("summary", `Proof trace (${result.proof.length} steps)`));
  if (!result.proof.length) proof.append(paragraph("No proof was produced."));
  for (const step of result.proof) {
    const detail = add(el("details"), el("summary", `${step.id}. ${step.clause}`),
      paragraph(`${step.rule}${step.source ? ": " + step.source : " from " + step.parents.join(", ")}`),
      el("pre", JSON.stringify({pivots: step.pivots, substitution: step.substitution}, null, 2)));
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
try {
  const data = await api("/api/examples");
  data.forEach((example, i) => examples.append(el("option", example.name, {value: String(i)})));
  load.onclick = () => {
    const example = data[Number(examples.value)];
    premises.value = example.premises.join("\n"); goal.value = example.goal; description.textContent = example.description;
    output.replaceChildren();
  };
  load.click(); await refreshHistory();
} catch (error) { output.replaceChildren(paragraph(error.message)); }
