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
    const series = JSON.parse(dataset.series!) as Array<{
      name: string;
      queued_at_seconds: number;
      queued_duration: number;
      run_duration: number;
    }>;

    new Chart(this.el as HTMLCanvasElement, {
      type: "bar",
      data: {
        labels: series.map((series) => series.name),
        datasets: [
          {
            label: "Queued (s)",
            data: series.map((job) => [
              job.queued_at_seconds,
              job.queued_at_seconds + job.queued_duration,
            ]),
          },
          {
            label: "Duration (s)",
            data: series.map((job) => [0, job.run_duration]),
          },
        ],
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
