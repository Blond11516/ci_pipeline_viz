import { HookContext } from "../../types/hook";
import Chart from "chart.js/auto";

interface JobData {
  name: string;
  start: number;
  end: number;
}

interface Series {
  name: string;
  data: Array<JobData>;
}

const timelineChart = {
  mounted(this: HookContext) {
    const dataset = this.el.dataset;
    const series = JSON.parse(dataset.series!) as Array<Series>;

    new Chart(this.el as HTMLCanvasElement, {
      type: "bar",
      data: {
        labels: series[0].data.map((series) => series.name),
        datasets: series.map((job) => ({
          label: job.name,
          data: job.data.map((datum) => [datum.start, datum.end]),
        })),
      },
      options: {
        indexAxis: "y",
        scales: {
          x: {
            min: 0,
            stacked: true,
          },
          y: {
            stacked: true,
          },
        },
      },
    });
  },
};

export default timelineChart;
