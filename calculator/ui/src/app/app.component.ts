import { Component } from '@angular/core';
import { AppService } from './app.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.sass']
})
export class AppComponent {
  constructor(
    private appService: AppService
  ) { }
  title = 'ui';

  calculate() {
    console.log('calculate')
    this.appService.get('http://0.0.0.0:9293/calculate')
      .subscribe((data: any) => {
        console.log('data', data)
      },
      error => {
        console.log(error)
      });
  }
}
