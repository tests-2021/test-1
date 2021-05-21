import { Component } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { tap, map } from 'rxjs/operators';


@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})


export class AppComponent {
  constructor(
  private http: HttpClient) { }

  calculation = {
    result: null
  }

  calculate(): void {
    this.calculation = {
      result: 'Производится расчет'
    }

    this.http
      .get('http://0.0.0.0:9293/calculate', {responseType: 'json'})
      .subscribe(
        data => {
          console.warn(data)
          this.calculation = data as any
        }
      );
  }
}
