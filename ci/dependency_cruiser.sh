module.exports = {
  forbidden: [
    {
      name: "no-backward-ou-calls",
      from: { path: "^src/ou-05" },
      to: { path: "^src/ou-03" }
    },
    {
      name: "no-control-plane-from-executor",
      from: { path: "^src/ou-05" },
      to: { path: "^src/ou-01" }
    }
  ]
};
